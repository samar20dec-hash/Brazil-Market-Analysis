class ETLReport:

    def __init__(self):
        self.tables_loaded = 0
        self.rows_imported = 0
        self.failed_tables = 0

    def success(self, rows):
        self.tables_loaded += 1
        self.rows_imported += rows

    def fail(self):
        self.failed_tables += 1

    def show(self):
        print("\n" + "=" * 60)
        print("ETL SUMMARY")
        print("=" * 60)
        print(f"Tables Loaded : {self.tables_loaded}")
        print(f"Rows Imported : {self.rows_imported:,}")
        print(f"Failed Tables : {self.failed_tables}")
        print("=" * 60)