class Pagination {
  final int total, limit, pages, page;
  final String? order, query;

  Pagination(
      {this.total = 0,
      this.limit = 0,
      this.pages = 0,
      this.page = 1,
      this.order,
      this.query});
}
