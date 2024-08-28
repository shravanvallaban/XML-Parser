import React, { useState } from 'react';
import axios from 'axios';
import { UploadCloud, FileText, User, Building, Calendar, Search } from 'lucide-react';

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
        headers: { 'Content-Type': 'multipart/form-data' }
      });

      setUploadStatus({
        type: 'success',
        message: 'File uploaded successfully',
        details: response.data
      });
      setFile(null);
      fetchSearchResults(searchTerm);
    } catch (error) {
      console.error('Error uploading file:', error);
      setUploadStatus({
        type: 'error',
        message: 'Error uploading file',
        details: error.response?.data?.error || error.message || 'An unexpected error occurred'
      });
    }
  };


  const handleSearch = (event) => {
    event.preventDefault();
    fetchSearchResults(searchTerm);
  };

  const fetchSearchResults = async (term) => {
    try {
      const response = await axios.get(`/api/files/search?filename=${encodeURIComponent(term)}`);
      // The API returns data.files, not data.results
      setFileList(response.data.files || []);
    } catch (error) {
      console.error('Error fetching search results:', error);
      setUploadStatus({
        type: 'error',
        message: 'Error fetching search results',
        details: error.response?.data?.error || error.message || 'An unexpected error occurred'
      });
      // Set fileList to an empty array in case of error
      setFileList([]);
    }
  };

  return (
    <div className="container">
      <h1>XML File Upload and Search</h1>

      {/* File Upload Form */}
      <form onSubmit={handleSubmit}>
        <div>
          <input
            type="file"
            onChange={handleFileChange}
            accept=".xml"
          />
          <button
            type="submit"
            disabled={!file}
          >
            <UploadCloud />
            Upload
          </button>
        </div>
      </form>

      {/* Upload Status */}
      {uploadStatus && (
        <div className={`alert ${uploadStatus.type === 'success' ? 'alert-success' : 'alert-error'}`}>
          <h4>{uploadStatus.type === 'success' ? 'Success' : 'Error'}</h4>
          <p>{uploadStatus.message}</p>
          {uploadStatus.details && (
            <pre>{JSON.stringify(uploadStatus.details, null, 2)}</pre>
          )}
        </div>
      )}

      {/* File Search Form */}
      <form onSubmit={handleSearch}>
        <div>
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search files by name"
          />
          <button type="submit">
            <Search />
            Search
          </button>
        </div>
      </form>

      {/* File List */}
      <h2>File List</h2>
      {fileList.length > 0 ? (
        <ul>
          {fileList.map((file) => (
            <li key={file.id}>
              <div>
                <FileText />
                <span>{file.upload_file_name}</span>
              </div>
              <div>
                <Calendar />
                {new Date(file.uploaded_time).toLocaleString()}
              </div>
              <div>
                <h3>
                  <User /> Plaintiff:
                </h3>
                <p>{file.plaintiff}</p>
              </div>
              <div>
                <h3>
                  <Building /> Defendants:
                </h3>
                <p>{file.defendants}</p>
              </div>
            </li>
          ))}
        </ul>
      ) : (
        <p>No files found.</p>
      )}
    </div>
  );
};

export default FileUpload;