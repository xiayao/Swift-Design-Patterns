let search = SearchTool(dataSources: SalesDataSource(), DevelopmentDataSource(), NewCoDirectoryAdapter())

print("--List--")
for e in search.employees {
	print("Name: \(e.name)")
}

print("--Search")
for e in search.search("VP", type: .TITLE) {
	print("Name: \(e.name), Title: \(e.title)")
}
