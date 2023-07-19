class Pagination {
  final int total, limit, pages, page;
  final String? order, query;

  // check if there is a next page
  bool get hasNext => page < pages;

  // check if there is a previous page
  bool get hasPrevious => page > 1;

  Pagination(
      {this.total = 0,
      this.limit = 0,
      this.pages = 0,
      this.page = 1,
      this.order,
      this.query});
}
