import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'farming_data.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create the kmg_mid table (main table)
    await db.execute('''
    CREATE TABLE kmg_mid (
      id INTEGER PRIMARY KEY,
      active BOOLEAN
    )
  ''');

    // Create the parcels table
    await db.execute('''
    CREATE TABLE parcels (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      kmg_mid_id INTEGER NOT NULL,
      gerk_pid TEXT,
      blok_id TEXT,
      m2 REAL,
      domace_ime TEXT,
      is_gerk BOOLEAN,
      coordinate REAL,
      FOREIGN KEY(kmg_mid_id) REFERENCES kmg_mid(id)
    )
  ''');

    // Create the jobs table detail_type TEXT,
    await db.execute('''
    CREATE TABLE jobs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parcel_id INTEGER,
      detail_type TEXT,
      job_type TEXT,
      date_time DATETIME NOT NULL,
      FOREIGN KEY(parcel_id) REFERENCES parcels(id)
    )
  ''');

    // Create the job_details table
    await db.execute('''
    CREATE TABLE job_details (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      job_id INTEGER,
      detail_type TEXT,
      type TEXT,
      culture TEXT,
      seed_quantity REAL,
      fert_quantity REAL,
      spray_quantity REAL,
      bales_on_field INTEGER,
      date_time DATETIME NOT NULL,
      FOREIGN KEY(job_id) REFERENCES jobs(id)
    )
  ''');
  }

  // Insert data into the kmg_mid table
  Future<int> insertKmgMid(int kmgMid) async {
    Database db = await database;

    // Set all kmg_mid entries to active: 0
    await db.update(
      'kmg_mid',
      {'active': 0},
    );

    // Check if kmg_mid already exists
    List<Map<String, dynamic>> existingKmgMid = await db.query(
      'kmg_mid',
      where: 'id = ?',
      whereArgs: [kmgMid],
    );

    if (existingKmgMid.isNotEmpty) {
      // kmg_mid already exists, update the active field to 1
      await db.update(
        'kmg_mid',
        {'active': 1}, // Set active to true
        where: 'id = ?',
        whereArgs: [kmgMid],
      );
      // Return the existing id
      return existingKmgMid.first['id'];
    } else {
      // Insert new kmg_mid with active set to 1
      return await db.insert(
        'kmg_mid',
        {
          'id': kmgMid,
          'active': 1,
        },
      );
    }
  }

  // Insert or update data in the parcels table
  Future<int> insertOrUpdateParcel(Map<String, dynamic> parcelData) async {
    Database db = await database;

    // Check if a parcel with the given kmg_mid_id and gerk_pid already exists
    List<Map<String, dynamic>> existingParcel = await db.query(
      'parcels',
      where: 'kmg_mid_id = ? AND gerk_pid = ?',
      whereArgs: [parcelData['kmg_mid_id'], parcelData['gerk_pid']],
    );

    if (existingParcel.isNotEmpty) {
      // Parcel exists, update the existing record
      return await db.update(
        'parcels',
        parcelData,
        where: 'kmg_mid_id = ? AND gerk_pid = ?',
        whereArgs: [parcelData['kmg_mid_id'], parcelData['gerk_pid']],
      );
    } else {
      // Parcel does not exist, insert a new record
      return await db.insert('parcels', parcelData);
    }
  }

  // Insert a job
  Future<int> insertJob(Map<String, dynamic> jobData) async {
    Database db = await database;
    return await db.insert('jobs', jobData);
  }

  // Insert job details
  Future<int> insertJobDetails(Map<String, dynamic> jobDetailsData) async {
    Database db = await database;
    return await db.insert('job_details', jobDetailsData);
  }

  // Get all data from kmg_mid table
  Future<List<Map<String, dynamic>>> getAllKmgMids() async {
    Database db = await database;
    return await db.query('kmg_mid');
  }

  // Get parcels for a specific kmg_mid
  Future<List<Map<String, dynamic>>> getParcelsForKmgMid(int kmgMidId) async {
    Database db = await database;
    return await db.query(
      'parcels',
      where: 'kmg_mid_id = ?',
      whereArgs: [kmgMidId],
    );
  }

  // Get jobs for a specific parcel
  Future<List<Map<String, dynamic>>> getJobsForParcel(int parcelId) async {
    Database db = await database;
    return await db.query(
      'jobs',
      where: 'parcel_id = ?',
      whereArgs: [parcelId],
    );
  }

  // Get job details for a specific job
  Future<List<Map<String, dynamic>>> getJobDetailsForJob(int jobId) async {
    Database db = await database;
    return await db.query(
      'job_details',
      where: 'job_id = ?',
      whereArgs: [jobId],
    );
  }

  // Function to get the last job done on a specific parcel
  Future<Map<String, dynamic>?> getLastJobForParcel(int parcelId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'jobs',
      where: 'parcel_id = ?',
      whereArgs: [parcelId],
      orderBy: 'date_time DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null; // Return null if no job exists for the given parcel
    }
  }

  Future<void> deleteJob(int jobId) async {
    Database db = await database;

    // Delete associated job details first
    await db.delete(
      'job_details',
      where: 'job_id = ?',
      whereArgs: [jobId],
    );

    // Then delete the job
    await db.delete(
      'jobs',
      where: 'id = ?',
      whereArgs: [jobId],
    );
  }

  // Function to delete a specific parcel and all its associated data
  Future<void> deleteParcel(int parcelId) async {
    Database db = await database;

    // Step 1: Get all jobs for the parcel
    List<Map<String, dynamic>> jobs = await db.query(
      'jobs',
      where: 'parcel_id = ?',
      whereArgs: [parcelId],
    );

    // Step 2: Delete all job details associated with these jobs
    for (var job in jobs) {
      await db.delete(
        'job_details',
        where: 'job_id = ?',
        whereArgs: [job['id']],
      );
    }

    // Step 3: Delete the jobs associated with the parcel
    await db.delete(
      'jobs',
      where: 'parcel_id = ?',
      whereArgs: [parcelId],
    );

    // Step 4: Delete the parcel itself
    await db.delete(
      'parcels',
      where: 'id = ?',
      whereArgs: [parcelId],
    );
  }

  // Insert new parcel
  Future<int> insertField(String name, double size) async {
    final db = await database;

    // Retrieve the active kmg_mid
    int? activeKmgMid = await getLastKmgMid();

    // Ensure that an active kmg_mid is available
    if (activeKmgMid == null) {
      throw Exception('No active KMG-MID found. Please set an active KMG-MID.');
    }

    // Insert parcel data using the active kmg_mid
    Map<String, dynamic> parcelData = {
      'kmg_mid_id': activeKmgMid,
      'm2': size,
      'is_gerk': false,
      'domace_ime': name,
    };

    return await db.insert('parcels', parcelData);
  }

  // Delete all data from kmg_mid table
  Future<void> deleteAllKmgMids() async {
    Database db = await database;
    await db.delete('kmg_mid');
  }

  // Method to get the first kmg_mid with enabled set to true
  Future<int?> getLastKmgMid() async {
    Database db = await database;

    // Get the first kmg_mid where enabled is true
    List<Map<String, dynamic>> result = await db.query(
      'kmg_mid',
      where: 'active = ?',
      whereArgs: [1], // 1 represents true in SQLite
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int?;
    } else {
      return null; // No kmg_mid with enabled = true found
    }
  }

  // Get job details for a specific job type along with parcel information
  Future<List<Map<String, dynamic>>> getJobDetailsByType(String jobType) async {
    Database db = await database;
    return await db.rawQuery('''
    SELECT jd.*, p.domace_ime, p.gerk_pid, p.m2
    FROM job_details jd
    JOIN jobs j ON jd.job_id = j.id
    JOIN parcels p ON j.parcel_id = p.id
    WHERE jd.detail_type = ?
    ORDER BY jd.date_time DESC
  ''', [jobType]);
  }

  // Delete a specific kmg_mid and associated parcels, jobs, and job details
  Future<void> deleteKmgMid(int kmgMidId) async {
    Database db = await database;

    // Get all parcels for this kmg_mid
    List<Map<String, dynamic>> parcels = await getParcelsForKmgMid(kmgMidId);
    for (var parcel in parcels) {
      // Get jobs for each parcel
      List<Map<String, dynamic>> jobs = await getJobsForParcel(parcel['id']);
      for (var job in jobs) {
        // Delete associated job details
        await db.delete(
          'job_details',
          where: 'job_id = ?',
          whereArgs: [job['id']],
        );
      }

      // Delete jobs
      await db.delete(
        'jobs',
        where: 'parcel_id = ?',
        whereArgs: [parcel['id']],
      );
    }

    // Delete parcels
    await db.delete(
      'parcels',
      where: 'kmg_mid_id = ?',
      whereArgs: [kmgMidId],
    );

    // Delete the kmg_mid
    await db.delete(
      'kmg_mid',
      where: 'id = ?',
      whereArgs: [kmgMidId],
    );
  }
}
