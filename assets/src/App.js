import React, { useState } from 'react';
import axios from 'axios';
import { UploadCloud, FileText, User, Building, Calendar, Search } from 'lucide-react';
import './App.css';

const FileUpload = () => {
  const [file, setFile] = useState(null);
  const [uploadStatus, setUploadStatus] = useState(null);
  const [fileList, setFileList] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');

  const handleFileChange = (event) => {
    setFile(event.target.files[0]);
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (!file) return;

    const formData = new FormData();
    formData.append('file', file);

    try {
      const response = await axios.post('/api/files', formData, {
        headers: { 
          'Content-Type': 'multipart/form-data',
          'Accept': 'application/vnd.api+json'
        }
      });

      setUploadStatus({
        type: 'success',
        message: 'File uploaded successfully',
        details: response.data.data.attributes
      });
      setFile(null);
    } catch (error) {
      console.error('Error uploading file:', error);
      setUploadStatus({
        type: 'error',
        message: 'Error uploading file',
        details: error.response?.data?.errors?.[0]?.detail || error.message || 'An unexpected error occurred'
      });
    }
  };

  const handleSearch = (event) => {
    event.preventDefault();
    fetchSearchResults(searchTerm);
  };

  const fetchSearchResults = async (term) => {
    try {
      const response = await axios.get(`/api/files?filename=${encodeURIComponent(term)}`, {
        headers: { 'Accept': 'application/vnd.api+json' }
      });
      setFileList(response.data.data || []);
    } catch (error) {
      console.error('Error fetching search results:', error);
      setUploadStatus({
        type: 'error',
        message: 'Error fetching search results',
        details: error.response?.data?.errors?.[0]?.detail || error.message || 'An unexpected error occurred'
      });
      setFileList([]);
    }
  };

  return (
    <div className="app-container">
      <div className="left-section">
        <div className="upload-section">
          <h2>XML File Upload</h2>
          <form onSubmit={handleSubmit} className="upload-form">
            <div className="file-input-wrapper">
              <input
                type="file"
                onChange={handleFileChange}
                accept=".xml"
                id="file-upload"
              />
              <label htmlFor="file-upload" className="file-label">
                <UploadCloud size={24} />
                {file ? file.name : 'Choose a file'}
              </label>
            </div>
            <button
              type="submit"
              disabled={!file}
              className="upload-button"
            >
              <UploadCloud size={24} />
              Upload
            </button>
          </form>
          {uploadStatus && (
            <div className={`alert ${uploadStatus.type === 'success' ? 'alert-success' : 'alert-error'}`}>
              <h4>{uploadStatus.type === 'success' ? 'Success' : 'Error'}</h4>
              <p>{uploadStatus.message}</p>
              {uploadStatus.details && (
                <pre>{JSON.stringify(uploadStatus.details, null, 2)}</pre>
              )}
            </div>
          )}
        </div>
        <div className="search-section">
          <h2>File Search</h2>
          <form onSubmit={handleSearch} className="search-form">
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search files by name"
              className="search-input"
            />
            <button type="submit" className="search-button">
              <Search size={24} />
              Search
            </button>
          </form>
        </div>
      </div>
      <div className="right-section">
        <div className="file-list">
          <h2>Search Results</h2>
          {fileList.length > 0 ? (
            <ul>
              {fileList.map((file) => (
                <li key={file.id} className="file-item">
                  <div className="file-header">
                    <FileText size={24} />
                    <span>{file.attributes.upload_file_name}</span>
                  </div>
                  <div className="file-date">
                    <Calendar size={18} />
                    {new Date(file.attributes.uploaded_time).toLocaleString()}
                  </div>
                  <div className="file-details">
                    <div className="plaintiff">
                      <h4>
                        <User size={18} /> Plaintiff:
                      </h4>
                      <p>{file.attributes.plaintiff}</p>
                    </div>
                    <div className="defendants">
                      <h4>
                        <Building size={18} /> Defendants:
                      </h4>
                      <p>{file.attributes.defendants}</p>
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <p>No files found.</p>
          )}
        </div>
      </div>
    </div>
  );
};

export default FileUpload;