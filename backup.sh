#!/bin/bash

# Image Collection Portal - Backup Script
# This script creates backups of the database and uploaded files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
DB_BACKUP_FILE="database_backup_$DATE.sql"
FILES_BACKUP_FILE="uploads_backup_$DATE.tar.gz"
COMPLETE_BACKUP_FILE="complete_backup_$DATE.tar.gz"

# Create backup directory
create_backup_dir() {
    print_status "Creating backup directory..."
    mkdir -p "$BACKUP_DIR"
    print_success "Backup directory created: $BACKUP_DIR"
}

# Backup database
backup_database() {
    print_status "Creating database backup..."
    
    if docker-compose exec -T postgres pg_dump -U portal_user image_collection_db > "$BACKUP_DIR/$DB_BACKUP_FILE"; then
        print_success "Database backup created: $DB_BACKUP_FILE"
        print_status "Database backup size: $(du -h "$BACKUP_DIR/$DB_BACKUP_FILE" | cut -f1)"
    else
        print_error "Failed to create database backup"
        exit 1
    fi
}

# Backup uploaded files
backup_files() {
    print_status "Creating uploaded files backup..."
    
    # Get the volume path
    VOLUME_PATH=$(docker volume inspect portal_upload_data --format '{{.Mountpoint}}')
    
    if [ -z "$VOLUME_PATH" ]; then
        print_error "Could not find upload volume"
        exit 1
    fi
    
    # Create tar archive of uploaded files
    if tar -czf "$BACKUP_DIR/$FILES_BACKUP_FILE" -C "$VOLUME_PATH" .; then
        print_success "Files backup created: $FILES_BACKUP_FILE"
        print_status "Files backup size: $(du -h "$BACKUP_DIR/$FILES_BACKUP_FILE" | cut -f1)"
    else
        print_error "Failed to create files backup"
        exit 1
    fi
}

# Create complete backup archive
create_complete_backup() {
    print_status "Creating complete backup archive..."
    
    if tar -czf "$BACKUP_DIR/$COMPLETE_BACKUP_FILE" -C "$BACKUP_DIR" "$DB_BACKUP_FILE" "$FILES_BACKUP_FILE"; then
        print_success "Complete backup created: $COMPLETE_BACKUP_FILE"
        print_status "Complete backup size: $(du -h "$BACKUP_DIR/$COMPLETE_BACKUP_FILE" | cut -f1)"
        
        # Clean up individual files
        rm "$BACKUP_DIR/$DB_BACKUP_FILE" "$BACKUP_DIR/$FILES_BACKUP_FILE"
        print_status "Cleaned up individual backup files"
    else
        print_error "Failed to create complete backup"
        exit 1
    fi
}

# Clean old backups
cleanup_old_backups() {
    print_status "Cleaning up old backups (keeping last 7 days)..."
    
    # Remove backups older than 7 days
    find "$BACKUP_DIR" -name "complete_backup_*.tar.gz" -mtime +7 -delete 2>/dev/null || true
    find "$BACKUP_DIR" -name "database_backup_*.sql" -mtime +7 -delete 2>/dev/null || true
    find "$BACKUP_DIR" -name "uploads_backup_*.tar.gz" -mtime +7 -delete 2>/dev/null || true
    
    print_success "Old backups cleaned up"
}

# Show backup information
show_backup_info() {
    print_status "Backup Information:"
    echo -e "  ${GREEN}Backup Directory:${NC} $BACKUP_DIR"
    echo -e "  ${GREEN}Complete Backup:${NC} $COMPLETE_BACKUP_FILE"
    echo -e "  ${GREEN}Total Size:${NC} $(du -sh "$BACKUP_DIR" | cut -f1)"
    
    echo ""
    print_status "Available backups:"
    ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || print_warning "No complete backups found"
}

# Restore function
restore_backup() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        print_error "Please specify a backup file to restore"
        echo "Usage: $0 restore <backup_file>"
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    print_warning "This will overwrite current data. Are you sure? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_status "Restore cancelled"
        exit 0
    fi
    
    print_status "Restoring from backup: $backup_file"
    
    # Extract backup
    temp_dir=$(mktemp -d)
    tar -xzf "$backup_file" -C "$temp_dir"
    
    # Restore database
    print_status "Restoring database..."
    docker-compose exec -T postgres psql -U portal_user -d image_collection_db < "$temp_dir"/*.sql
    
    # Restore files
    print_status "Restoring uploaded files..."
    VOLUME_PATH=$(docker volume inspect portal_upload_data --format '{{.Mountpoint}}')
    tar -xzf "$temp_dir"/*.tar.gz -C "$VOLUME_PATH"
    
    # Cleanup
    rm -rf "$temp_dir"
    
    print_success "Restore completed successfully"
}

# Main function
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Image Collection Portal Backup${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    
    # Check if services are running
    if ! docker-compose ps | grep -q "Up"; then
        print_error "Services are not running. Please start the application first."
        exit 1
    fi
    
    create_backup_dir
    backup_database
    backup_files
    create_complete_backup
    cleanup_old_backups
    show_backup_info
    
    echo ""
    print_success "Backup completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    "restore")
        restore_backup "$2"
        ;;
    "list")
        print_status "Available backups:"
        ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || print_warning "No backups found"
        ;;
    "clean")
        print_status "Cleaning up old backups..."
        cleanup_old_backups
        print_success "Cleanup completed"
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)  Create a complete backup"
        echo "  restore <file>  Restore from backup file"
        echo "  list       List available backups"
        echo "  clean      Clean up old backups"
        echo "  help       Show this help message"
        ;;
    *)
        main
        ;;
esac 