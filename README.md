# AgriLog - Farm Management App
AgriLog is a Flutter-based mobile application designed to help farmers manage their fields, track job operations, record costs, and optimize agricultural tasks. It integrates features like exporting data to CSV, managing job histories, and visualizing parcel operations.

# Features
- Parcel Management: Easily add, edit, and delete parcels with details such as GERK-pid, size, and operation history.
- Job Tracking: Keep track of operations such as seeding, fertilizing, spraying, plowing, baling, and harvesting. View operation history for each field, and get a summary of operations over time.
- Data Export: Export job history and operational data to CSV format with date range selection. Manage and download CSV files directly from the app.
- Cost Management: Record and manage costs related to seeds, fertilizers, sprays, and labor, allowing you to track expenses over time (planned feature).
- Last Operation Overview: Get an overview of the last operation for each parcel including the operation type, date, and area covered.
- Custom Date Ranges: Filter job operations and generate summaries for specific date intervals (monthly, yearly, or custom).
- GERK Management: Integration with KMG-MID for fetching GERK-related data.
- Color-Coded Operations: Visualize operations with color-coded fields for easier tracking.
- Firebase Integration: App setup for future cloud-based expansion with Firebase, ensuring scalable data management.

# Planned Features

- Firebase Migration: Expand the app by integrating Firebase for real-time data synchronization and cloud backup.
- Aerial Images: Integration with satellite imagery providers to give farmers a bird's-eye view of their fields.
- Weather Data: Receive real-time weather updates and notifications directly in the app.
- Cost Analytics: Manage and visualize the costs associated with operations, inputs, and labor.
- Agri-Store Integration: Connect with local agricultural stores for streamlined ordering of seeds, fertilizers, and other materials.

# Technology Stack
- Flutter & Dart: Cross-platform development framework for building mobile apps on both iOS and Android.
- SQLite: Local database for storing job, parcel, and operation data.
- Firebase: Cloud-based backend planned for future releases.
- CSV Export: Export operational data to CSV files, accessible via external storage.

# How to Use
1. Add Parcels: Begin by adding parcels with the option to fetch GERK data using the KMG-MID number.
2. Track Jobs: Record field jobs and view operation history on a per-parcel basis.
3. Export Data: Export job data to CSV with customizable date ranges and save the file to an easily accessible location.
4. Track Costs (Upcoming): Log expenses for each job and get a summary of total costs for each parcel or operation.
