class ApiBase {
  static const String baseUrl = "https://api.renwidjaya.my.id";

  // Auth
  static const String login = "/api/v1-auth/login";
  static const String register = "/api/v1-auth/register";
  static const String userDetail = "/api/v1-auth/user";

  // Presensi
  static const String presensiList = "/api/v1-presensi/lists";
  static const String presensiLast =
      "/api/v1-presensi/last/"; // + {id_karyawan}
  static const String checkin = "/api/v1-presensi/checkin";
  static const String checkinUpdate = "/api/v1-presensi/checkin"; // PUT + {id}
  static const String riwayatAbsensi =
      "/api/v1-presensi/karyawan/"; // + {id_karyawan}
  static const String statistik = "/api/v1-presensi/statistik";
  static const String export = "/api/v1-presensi/export";
  static const String reportAll = "/api/v1-presensi/report/all";

  // File upload
  static const String profilPhoto = "/profil";
  static const String presensiPhoto = "/presensi";
}
