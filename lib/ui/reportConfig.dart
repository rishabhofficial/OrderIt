class ReportConfig {
  final List<String> companies;
  final String division;
  final DateTime startDate;
  final DateTime endDate;
  final String contactName;
  final String contactPhone;
  final String email;
  final String reportName;

  ReportConfig({
    this.companies,
    this.division,
    this.startDate,
    this.endDate,
    this.contactName = '',
    this.contactPhone = '',
    this.email = '',
    this.reportName = '',
  });

  ReportConfig copyWith({
    List<String> companies,
    String division,
    DateTime startDate,
    DateTime endDate,
    String contactName,
    String contactPhone,
    String email,
    String reportName,
  }) {
    return ReportConfig(
      companies: companies ?? this.companies,
      division: division ?? this.division,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      email: email ?? this.email,
      reportName: reportName ?? this.reportName,
    );
  }
}

enum DateRangeType {
  custom,
  lastWeek,
  lastMonth,
  lastQuarter,
  lastFinancialYear,
  currentMonth,
  currentQuarter,
  currentFinancialYear,
}

class DateRangeHelper {
  static Map<DateRangeType, String> getDisplayNames() {
    return {
      DateRangeType.custom: 'Custom Range',
      DateRangeType.lastWeek: 'Last Week',
      DateRangeType.lastMonth: 'Last Month',
      DateRangeType.lastQuarter: 'Last Quarter',
      DateRangeType.lastFinancialYear: 'Last Financial Year',
      DateRangeType.currentMonth: 'Current Month',
      DateRangeType.currentQuarter: 'Current Quarter',
      DateRangeType.currentFinancialYear: 'Current Financial Year',
    };
  }

  static Map<String, DateTime> getDateRange(DateRangeType type) {
    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (type) {
      case DateRangeType.lastWeek:
        endDate = now.subtract(Duration(days: now.weekday));
        startDate = endDate.subtract(Duration(days: 6));
        break;
      case DateRangeType.lastMonth:
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0);
        break;
      case DateRangeType.lastQuarter:
        int currentQuarter = ((now.month - 1) / 3).floor();
        int lastQuarter = currentQuarter == 0 ? 3 : currentQuarter - 1;
        int lastQuarterYear = currentQuarter == 0 ? now.year - 1 : now.year;
        startDate = DateTime(lastQuarterYear, lastQuarter * 3 + 1, 1);
        endDate = DateTime(lastQuarterYear, lastQuarter * 3 + 3, 0);
        break;
      case DateRangeType.lastFinancialYear:
        int currentFY = now.month >= 4 ? now.year : now.year - 1;
        startDate = DateTime(currentFY - 1, 4, 1);
        endDate = DateTime(currentFY, 3, 31);
        break;
      case DateRangeType.currentMonth:
        startDate = DateTime(now.year, now.month, 1);
        endDate = now;
        break;
      case DateRangeType.currentQuarter:
        int currentQuarter = ((now.month - 1) / 3).floor();
        startDate = DateTime(now.year, currentQuarter * 3 + 1, 1);
        endDate = now;
        break;
      case DateRangeType.currentFinancialYear:
        int currentFY = now.month >= 4 ? now.year : now.year - 1;
        startDate = DateTime(currentFY, 4, 1);
        endDate = now;
        break;
      case DateRangeType.custom:
      default:
        startDate = now.subtract(Duration(days: 30));
        endDate = now;
        break;
    }

    return {
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}
