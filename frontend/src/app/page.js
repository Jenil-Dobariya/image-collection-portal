'use client'

import { useState } from "react";
import axios from "axios";
import jsPDF from "jspdf";
import styles from "./page.module.css";

const API_URL = "http://localhost:3001/api";

export default function Home() {
  // Form state divided into logical parts
  const [step, setStep] = useState(1); // 1: Consent, 2: OTP, 3: Data Upload
  const [consentData, setConsentData] = useState({
    fullName: "",
    age: "",
    gender: "",
    email: "",
    consentChecked: false,
  });
  const [otp, setOtp] = useState("");
  const [images, setImages] = useState([]);
  const [imageDates, setImageDates] = useState([]);
  const [previews, setPreviews] = useState([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [successMessage, setSuccessMessage] = useState("");

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
    //   await axios.post(`${API_URL}/send-otp`, { email: consentData.email });
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
    //   await axios.post(`${API_URL}/verify-otp`, {
    //     email: consentData.email,
    //     otp,
    //   });
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
    setImageDates((prev) => [
      ...prev,
      ...Array(validFiles.length).fill(new Date().toISOString().split("T")[0]),
    ]);

    const newPreviews = validFiles.map((file) => URL.createObjectURL(file));
    setPreviews((prev) => [...prev, ...newPreviews]);
  };

  const handleDateChange = (index, date) => {
    const newDates = [...imageDates];
    newDates[index] = date;
    setImageDates(newDates);
  };

  const generateConsentPdf = () => {
    const doc = new jsPDF();
    doc.setFontSize(16);
    doc.text("Consent Form Confirmation", 20, 20);
    doc.setFontSize(12);
    doc.text(`Full Name: ${consentData.fullName}`, 20, 40);
    doc.text(`Age: ${consentData.age}`, 20, 50);
    doc.text(`Gender: ${consentData.gender}`, 20, 60);
    doc.text(`Email: ${consentData.email}`, 20, 70);
    doc.text(
      `Consent Given: ${consentData.consentChecked ? "Yes" : "No"}`,
      20,
      80
    );
    doc.text(`Timestamp: ${new Date().toLocaleString()}`, 20, 90);
    return doc.output("blob");
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

    // Append image dates as a JSON string
    formData.append("imageDates", JSON.stringify(imageDates));

    // Generate and append consent PDF
    const pdfBlob = generateConsentPdf();
    formData.append("consentForm", pdfBlob, "__consent_form.pdf");

    try {
    //   const response = await axios.post(`${API_URL}/submit`, formData, {
    //     headers: { "Content-Type": "multipart/form-data" },
    //   });
    //   setSuccessMessage(response.data.message);
      setStep(4); // Success step
    } catch (err) {
      setError(err.response?.data?.message || "Submission failed.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={styles.container}>
      <main className={styles.main}>
        <h1 className={styles.title}>Student Image Collection Portal</h1>
        <p className={styles.description}>
          Please follow the steps below to submit your images.
        </p>

        {error && <p className={styles.error}>{error}</p>}

        {step === 1 && (
          <form onSubmit={handleSendOtp} className={styles.form}>
            <h2>Consent and Verification</h2>
            <div className={styles.consentBox}>
              <p>
                Please read the following consent form carefully. By checking
                this box, you agree to the terms outlined, allowing the use of
                your provided data and images for academic research purposes...
              </p>
            </div>
            <label>
              <input
                type="checkbox"
                name="consentChecked"
                checked={consentData.consentChecked}
                onChange={handleConsentChange}
                required
              />
              I have read and agree to the consent form.
            </label>
            <input
              type="text"
              name="fullName"
              placeholder="Full Name"
              value={consentData.fullName}
              onChange={handleConsentChange}
              required
            />
            <input
              type="number"
              name="age"
              placeholder="Age"
              value={consentData.age}
              onChange={handleConsentChange}
              required
            />
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
            <input
              type="email"
              name="email"
              placeholder="IITK Email ID"
              value={consentData.email}
              onChange={handleConsentChange}
              required
            />
            <button type="submit" disabled={loading}>
              {loading ? "Sending..." : "Send OTP & Verify Email"}
            </button>
          </form>
        )}

        {step === 2 && (
          <form onSubmit={handleVerifyOtp} className={styles.form}>
            <h2>Enter OTP</h2>
            <p>
              An OTP has been sent to <strong>{consentData.email}</strong>.
              Please enter it below.
            </p>
            <input
              type="text"
              value={otp}
              onChange={(e) => setOtp(e.target.value)}
              placeholder="6-Digit OTP"
              required
            />
            <button type="submit" disabled={loading}>
              {loading ? "Verifying..." : "Verify OTP"}
            </button>
          </form>
        )}

        {step === 3 && (
          <form onSubmit={handleSubmit} className={styles.form}>
            <h2>Upload Your Images</h2>
            <p>Your email is verified. Please upload up to 10 images.</p>
            <input
              type="file"
              accept="image/png, image/jpeg"
              multiple
              onChange={handleImageChange}
            />

            <div className={styles.previewContainer}>
              {previews.map((preview, index) => (
                <div key={index} className={styles.preview}>
                  <img src={preview} alt={`preview ${index}`} />
                  <label>Date of Image:</label>
                  <input
                    type="date"
                    value={imageDates[index]}
                    onChange={(e) => handleDateChange(index, e.target.value)}
                    required
                  />
                </div>
              ))}
            </div>

            {images.length > 0 && (
              <button type="submit" disabled={loading}>
                {loading ? "Submitting..." : `Submit ${images.length} Image(s)`}
              </button>
            )}
          </form>
        )}

        {step === 4 && (
          <div className={styles.success}>
            <h2>✅ Thank You!</h2>
            <p>{successMessage}</p>
          </div>
        )}
      </main>
    </div>
  );
}
