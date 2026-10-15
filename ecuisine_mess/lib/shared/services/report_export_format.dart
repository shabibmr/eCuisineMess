/// File type a generated report can be saved as.
enum ReportExportFormat {
  csv('csv', 'CSV'),
  excel('xlsx', 'Excel'),
  pdf('pdf', 'PDF');

  const ReportExportFormat(this.extension, this.label);

  final String extension;
  final String label;
}
