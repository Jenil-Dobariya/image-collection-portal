"use client";

import { useState, useEffect } from "react";
import axios from "axios";
import jsPDF from "jspdf";
import styles from "./page.module.css";

const API_URL = "http://localhost:3001/api";

export default function Home() {
  // Form state divided into logical parts
  const [step, setStep] = useState(1); // 1: Consent, 2: OTP, 3: Data Upload, 4: Success
  const [consentData, setConsentData] = useState({
    fullName: "",
    age: "",
    gender: "",
    email: "",
    consentChecked: false,
  });
  const [otp, setOtp] = useState("");
  const [images, setImages] = useState([]);
  const [imageAges, setImageAges] = useState([]);
  const [previews, setPreviews] = useState([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [successMessage, setSuccessMessage] = useState("");

  // Persist form data on refresh
  useEffect(() => {
    const savedConsentData = localStorage.getItem('consentData');
    const savedStep = localStorage.getItem('currentStep');
    const savedOtp = localStorage.getItem('otp');

    if (savedConsentData) {
      setConsentData(JSON.parse(savedConsentData));
    }
    if (savedStep) {
      setStep(parseInt(savedStep));
    }
    if (savedOtp && parseInt(savedStep) >= 2) {
      setOtp(savedOtp);
    }
  }, []);

  // Save form data to localStorage
  useEffect(() => {
    localStorage.setItem('consentData', JSON.stringify(consentData));
    localStorage.setItem('currentStep', step.toString());
    if (otp) {
      localStorage.setItem('otp', otp);
    }
  }, [consentData, step, otp]);

  const handleConsentChange = (e) => {
    const { name, value, type, checked } = e.target;
    setConsentData((prev) => ({
      ...prev,
      [name]: type === "checkbox" ? checked : value,
    }));
  };

  const handleSendOtp = async (e) => {
    e.preventDefault();
    if (!consentData.consentChecked) {
      setError("You must agree to the consent form.");
      return;
    }
    if (!consentData.email.endsWith("@iitk.ac.in")) {
      setError("A valid IITK email is required.");
      return;
    }
    setLoading(true);
    setError("");
    try {
      await axios.post(`${API_URL}/send-otp`, { email: consentData.email });
      setStep(2); // Move to OTP verification step
    } catch (err) {
      setError(err.response?.data?.message || "Failed to send OTP.");
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOtp = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      await axios.post(`${API_URL}/verify-otp`, {
        email: consentData.email,
        otp,
      });
      setStep(3); // Move to data upload step
    } catch (err) {
      setError(err.response?.data?.message || "Failed to verify OTP.");
    } finally {
      setLoading(false);
    }
  };

  const handleImageChange = (e) => {
    const files = Array.from(e.target.files);
    if (files.length + images.length > 10) {
      setError("You can upload a maximum of 10 images.");
      return;
    }

    const validFiles = files.filter(
      (file) =>
        (file.type === "image/jpeg" || file.type === "image/png") &&
        file.size <= 5 * 1024 * 1024
    );
    if (validFiles.length !== files.length) {
      setError("Invalid file. Only JPG/PNG up to 5MB are allowed.");
      return;
    }

    setError("");
    setImages((prev) => [...prev, ...validFiles]);
    setImageAges((prev) => [
      ...prev,
      ...Array(validFiles.length).fill(''),
    ]);

    const newPreviews = validFiles.map((file) => URL.createObjectURL(file));
    setPreviews((prev) => [...prev, ...newPreviews]);
  };

  const handleAgeChange = (index, age) => {
    const newAges = [...imageAges];
    newAges[index] = age;
    setImageAges(newAges);
  };

  const removeImage = (index) => {
    setImages(prev => prev.filter((_, i) => i !== index));
    setImageAges(prev => prev.filter((_, i) => i !== index));
    setPreviews(prev => prev.filter((_, i) => i !== index));
  };

  const generateConsentPdf = () => {
    const doc = new jsPDF();

    // Header
    doc.setFontSize(20);
    doc.setTextColor(44, 62, 80);
    doc.text("Smart Search and Rescue Project", 20, 20);
    doc.text("Consent Form", 20, 30);

    doc.setFontSize(12);
    doc.setTextColor(52, 73, 94);
    doc.text("Date: " + new Date().toLocaleDateString(), 20, 45);
    doc.text("Time: " + new Date().toLocaleTimeString(), 20, 55);

    // Consent Statement
    doc.setFontSize(14);
    doc.setTextColor(44, 62, 80);
    doc.text("Consent Statement:", 20, 75);

    doc.setFontSize(11);
    doc.setTextColor(52, 73, 94);
    const consentText = [
      "I have been informed and understood the objective of the project",
      "and the requirement of face images. I have had the opportunity to",
      "ask any questions related to this study, and received satisfactory answers",
      "to my questions, and any additional details I wanted.",
      "",
      "I have no objection, and am giving my consent, if my images",
      "are used for training purpose.",
      "",
      "Please tick if you agree with the following:",
      "☑ I have no objection, and am giving my consent, if my images",
      "   are used for training purpose."
    ];

    let yPos = 85;
    consentText.forEach(line => {
      doc.text(line, 20, yPos);
      yPos += 6;
    });

    // Participant Information
    doc.setFontSize(14);
    doc.setTextColor(44, 62, 80);
    doc.text("Participant Information:", 20, yPos + 10);

    doc.setFontSize(11);
    doc.setTextColor(52, 73, 94);
    yPos += 20;
    doc.text(`Full Name: ${consentData.fullName}`, 20, yPos);
    doc.text(`Age: ${consentData.age}`, 20, yPos + 8);
    doc.text(`Gender: ${consentData.gender}`, 20, yPos + 16);
    doc.text(`Email: ${consentData.email}`, 20, yPos + 24);

    // Footer
    doc.setFontSize(10);
    doc.setTextColor(127, 140, 141);
    doc.text("This document is generated automatically by the Smart Search and Rescue Project Portal", 20, 270);

    return doc.output("blob");
  };

  const downloadConsentPdf = () => {
    const pdfBlob = generateConsentPdf();
    const url = URL.createObjectURL(pdfBlob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `consent_form_${consentData.fullName.replace(/\s+/g, '_')}.pdf`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (images.length === 0) {
      setError("Please upload at least one image.");
      return;
    }
    setLoading(true);
    setError("");
    setSuccessMessage("");

    const formData = new FormData();
    // Append student data
    formData.append("name", consentData.fullName);
    formData.append("age", consentData.age);
    formData.append("email", consentData.email);
    formData.append("consentGiven", consentData.consentChecked);

    // Append images
    images.forEach((image) => {
      formData.append("images", image);
    });

    // Append image ages as a JSON string
    formData.append("imageAges", JSON.stringify(imageAges));

    // Generate and append consent PDF
    const pdfBlob = generateConsentPdf();
    formData.append("consentForm", pdfBlob, "__consent_form.pdf");

    try {
      const response = await axios.post(`${API_URL}/submit`, formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      setSuccessMessage(response.data.message);
      setStep(4); // Success step
    } catch (err) {
      setError(err.response?.data?.message || "Submission failed.");
    } finally {
      setLoading(false);
    }
  };

  const resetForm = () => {
    setConsentData({
      fullName: "",
      age: "",
      gender: "",
      email: "",
      consentChecked: false,
    });
    setOtp("");
    setImages([]);
    setImageAges([]);
    setPreviews([]);
    setError("");
    setSuccessMessage("");
    setStep(1);
    localStorage.removeItem('consentData');
    localStorage.removeItem('currentStep');
    localStorage.removeItem('otp');
  };

  return (
    <div className={styles.container}>
      <main className={styles.main}>
        <div className={styles.header}>
          <h1 className={styles.title}>Smart Search and Rescue Project</h1>
          <p className={styles.subtitle}>Image Collection Portal</p>
          <div className={styles.progressBar}>
            <div
              className={styles.progressFill}
              style={{ width: `${(step / 4) * 100}%` }}
            ></div>
          </div>
          <div className={styles.steps}>
            <span className={step >= 1 ? styles.activeStep : styles.step}>Consent</span>
            <span className={step >= 2 ? styles.activeStep : styles.step}>OTP</span>
            <span className={step >= 3 ? styles.activeStep : styles.step}>Upload</span>
            <span className={step >= 4 ? styles.activeStep : styles.step}>Complete</span>
          </div>
        </div>

        {error && <div className={styles.error}>{error}</div>}

        {step === 1 && (
          <form onSubmit={handleSendOtp} className={styles.form}>
            <div className={styles.formSection}>
              <h2>📋 Consent Form</h2>
              <div className={styles.consentBox}>
                <h3>Project Information</h3>
                <p>
                  <strong>Project Title:</strong> Smart Search and Rescue Project<br />
                  <strong>Objective:</strong> To develop advanced face recognition algorithms for search and rescue operations
                </p>

                <h3>Consent Statement</h3>
                <p>
                  I have been informed and understood the objective of the project
                  and the requirement of face images. I have had the opportunity to
                  ask any questions related to this study, and received satisfactory answers
                  to my questions, and any additional details I wanted.
                </p>

                <p>
                  I have no objection, and am giving my consent, if my images
                  are used for purpose.
                </p>

                <p><strong>Please tick if you agree with the following:</strong></p>

                <div className={styles.consentCheckbox}>
                  <label>
                    <input
                      type="checkbox"
                      name="consentChecked"
                      checked={consentData.consentChecked}
                      onChange={handleConsentChange}
                      required
                    />
                    <span>I have no objection, and am giving my consent, if my images are used for training purpose.</span>
                  </label>
                </div>
              </div>
            </div>

            <div className={styles.formSection}>
              <h2>👤 Participant Information</h2>
              <div className={styles.inputGrid}>
                <div className={styles.inputGroup}>
                  <label>Full Name *</label>
                  <input
                    type="text"
                    name="fullName"
                    placeholder="Enter your full name"
                    value={consentData.fullName}
                    onChange={handleConsentChange}
                    required
                  />
                </div>

                <div className={styles.inputGroup}>
                  <label>Age *</label>
                  <input
                    type="number"
                    name="age"
                    placeholder="Enter your age"
                    value={consentData.age}
                    onChange={handleConsentChange}
                    min="16"
                    max="100"
                    required
                  />
                </div>

                <div className={styles.inputGroup}>
                  <label>Gender *</label>
                  <select
                    name="gender"
                    value={consentData.gender}
                    onChange={handleConsentChange}
                    required
                  >
                    <option value="">Select Gender</option>
                    <option value="Male">Male</option>
                    <option value="Female">Female</option>
                    <option value="Other">Other</option>
                    <option value="Prefer not to say">Prefer not to say</option>
                  </select>
                </div>



                <div className={styles.inputGroup}>
                  <label>IITK Email ID *</label>
                  <input
                    type="email"
                    name="email"
                    placeholder="your.email@iitk.ac.in"
                    value={consentData.email}
                    onChange={handleConsentChange}
                    required
                  />
                </div>
              </div>
            </div>

            <div className={styles.formActions}>
              <button type="submit" className={styles.primaryButton} disabled={loading}>
                {loading ? "Sending OTP..." : "Send OTP & Verify Email"}
              </button>
            </div>
          </form>
        )}

        {step === 2 && (
          <form onSubmit={handleVerifyOtp} className={styles.form}>
            <div className={styles.formSection}>
              <h2>🔐 Email Verification</h2>
              <div className={styles.otpBox}>
                <p>
                  An OTP has been sent to <strong>{consentData.email}</strong>.
                  Please check your email and enter the 6-digit code below.
                </p>
                <div className={styles.otpInput}>
                  <input
                    type="text"
                    value={otp}
                    onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
                    placeholder="Enter 6-digit OTP"
                    maxLength="6"
                    required
                  />
                </div>
                <p className={styles.otpNote}>
                  💡 If you don&apos;t receive the email, check your spam folder or try again.
                </p>
              </div>
            </div>

            <div className={styles.formActions}>
              <button type="submit" className={styles.primaryButton} disabled={loading}>
                {loading ? "Verifying..." : "Verify OTP"}
              </button>
              <button
                type="button"
                className={styles.secondaryButton}
                onClick={() => setStep(1)}
              >
                ← Back to Consent Form
              </button>
            </div>
          </form>
        )}

        {step === 3 && (
          <form onSubmit={handleSubmit} className={styles.form}>
            <div className={styles.formSection}>
              <h2>📸 Upload Images</h2>
              <p className={styles.instruction}>
                Your email is verified! Please upload up to 10 images of yourself at different ages.
                For each image, please specify your age in that photo.
              </p>

              <div className={styles.uploadArea}>
                <input
                  type="file"
                  accept="image/png, image/jpeg"
                  multiple
                  onChange={handleImageChange}
                  id="image-upload"
                  className={styles.fileInput}
                />
                <label htmlFor="image-upload" className={styles.uploadLabel}>
                  <div className={styles.uploadIcon}>📁</div>
                  <div>Click to select images or drag and drop</div>
                  <div className={styles.uploadHint}>JPG/PNG files up to 5MB each</div>
                </label>
              </div>

              {previews.length > 0 && (
                <div className={styles.previewContainer}>
                  <h3>Selected Images ({previews.length}/10)</h3>
                  <div className={styles.imageGrid}>
                    {previews.map((preview, index) => (
                      <div key={index} className={styles.imageCard}>
                        <div className={styles.imageWrapper}>
                          <img src={preview} alt={`preview ${index}`} />
                          <button
                            type="button"
                            className={styles.removeButton}
                            onClick={() => removeImage(index)}
                          >
                            ×
                          </button>
                        </div>
                        <div className={styles.ageInput}>
                          <label>Age in this photo:</label>
                          <input
                            type="number"
                            placeholder="e.g., 21"
                            value={imageAges[index]}
                            onChange={(e) => handleAgeChange(index, e.target.value)}
                            min="1"
                            max="100"
                            required
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {images.length > 0 && (
                <div className={styles.formActions}>
                  <button type="submit" className={styles.primaryButton} disabled={loading}>
                    {loading ? "Submitting..." : `Submit ${images.length} Image(s)`}
                  </button>
                  <button
                    type="button"
                    className={styles.secondaryButton}
                    onClick={() => setStep(2)}
                  >
                    ← Back to OTP Verification
                  </button>
                </div>
              )}
            </div>
          </form>
        )}

        {step === 4 && (
          <div className={styles.success}>
            <div className={styles.successIcon}>✅</div>
            <h2>Submission Complete!</h2>
            <p>{successMessage}</p>

            <div className={styles.successActions}>
              <button
                onClick={downloadConsentPdf}
                className={styles.primaryButton}
              >
                📄 Download Consent Form (PDF)
              </button>
              <button
                onClick={resetForm}
                className={styles.secondaryButton}
              >
                📝 Fill Another Form
              </button>
            </div>

            <div className={styles.successInfo}>
              <h3>What happens next?</h3>
              <ul>
                <li>Your images will be processed for the Smart Search and Rescue project</li>
                <li>Your consent form has been saved with your submission</li>
                <li>You can download your consent form for your records</li>
                <li>Thank you for contributing to this important research!</li>
              </ul>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
