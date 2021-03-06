import UIKit

class ProductTableCell : UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var stockStepper: UIStepper!
    @IBOutlet weak var stockField: UITextField!
    
    var product: Product?;
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		NotificationCenter.default.addObserver(self, selector: #selector(handleStockLevelUpdate(notification:)), name: NSNotification.Name("stockUpdate"), object: nil)
	}
	
	@objc private func handleStockLevelUpdate(notification: NSNotification) {
		if let updatedProduct = notification.object as? Product {
			if updatedProduct.name == self.product?.name {
				DispatchQueue.main.async {
					self.stockStepper.value = Double(updatedProduct.stockLevel)
					self.stockField.text = String(updatedProduct.stockLevel)
				}
			}
		}
	}
}



var handler = { (p: Product) in
	print("Change: \(p.name) \(p.stockLevel) items in stock")
}

class ViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var totalStockLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var productStore = ProductDataStore()
	
	var products = [Product(name: "Kayak", description: "A boat for one person", category: "Watersports", price: 275.0, stockLevel: 10),
	                Product(name: "Lifejacket", description: "Protective and fashionable", category: "Watersports", price: 48.95, stockLevel: 14),
	                Product(name: "Soccer Ball", description: "FIFA-approved size and weight", category: "Soccer", price: 19.5, stockLevel: 32),
	                Product(name: "Corner Flags", description: "Give your playing field a professional touch", category: "Soccer", price: 34.95, stockLevel: 1),
	                Product(name: "Stadium", description: "Flat-packed 35,000-seat stadium", category: "Soccer", price: 79500.0, stockLevel: 4),
	                Product(name: "Thinking Cap", description: "Improve your brain efficiency by 75%", category: "Chess", price: 16.0, stockLevel: 8),
	                Product(name: "Unsteady Chair", description: "Secretly give your opponent a disadvantage", category: "Chess", price: 29.95, stockLevel: 3),
	                Product(name: "Human Chess Board", description: "A fun game for the family", category: "Chess", price: 75.0, stockLevel: 2),
	                Product(name: "Bling-Bling King", description: "A fun game for the family", category: "Chess", price: 75.0, stockLevel: 2),
	                Product(name: "Bling-Bling King", description: "Gold-plated, diamond-studded King", category: "Chess", price: 1200.0, stockLevel: 4)]

    override func viewDidLoad() {
        super.viewDidLoad()
		
//		productStore.callback = { (p: Product) in
//			for cell in self.tableView.visibleCells {
//				if let pcell = cell as? ProductTableCell {
//					if pcell.product?.name == p.name {
//						pcell.stockStepper.value = Double(p.stockLevel)
//						pcell.stockField.text = String(p.stockLevel)
//					}
//				}
//			}
//		}
        displayStockTotal();
		
		let bridge = EventBridge(callback: updateStockLevel)
		productStore.callback = bridge.inputCallback
    }
	
	override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
		if event?.subtype == UIEventSubtype.motionShake {
			print("Shake motion detected")
			undoManager?.undo()
		}
	}
	
	func updateStockLevel(name: String, level: Int) {
		for cell in self.tableView.visibleCells {
			if  let pcell = cell as? ProductTableCell {
				pcell.stockStepper.value = Double(level)
				pcell.stockField.text = String(level)
			}
		}
		
		displayStockTotal()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func tableView(_ tableView: UITableView,
        numberOfRowsInSection section: Int) -> Int {
        return productStore.products.count;
    }
    
    func tableView(_ tableView: UITableView,
        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let product = products[indexPath.row];
		let product = productStore.products[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell") as! ProductTableCell
        cell.product = product
        cell.nameLabel.text = product.name;
        cell.descriptionLabel.text = product.productDescription;
        cell.stockStepper.value = Double(product.stockLevel);
        cell.stockField.text = String(product.stockLevel);
		CellFormatter.createChain().formatCell(cell: cell)
        return cell;
    }
    
    @IBAction func stockLevelDidChange(_ sender: AnyObject) {
        if var currentCell = sender as? UIView {
            while (true) {
                currentCell = currentCell.superview!;
                if let cell = currentCell as? ProductTableCell {
					if let product = cell.product {
//						let dict: Dictionary = [product.name: product.stockLevel]
						
//						undoManager?.registerUndo(withTarget: self, selector: #selector(undoStockLevel(data:)), object: dict)
						undoManager?.registerUndo(withTarget: self, selector: #selector(resetState), object: nil)
						
						if let stepper = sender as? UIStepper {
							product.stockLevel = Int(stepper.value)
						} else if let textField = sender as? UITextField {
							if let newValue = Int(textField.text!) {
								product.stockLevel = newValue
							}
						}
//						cell.stockStepper.value = Double(product.stockLevel)
//						cell.stockField.text = String(product.stockLevel)
						productLogger.logItem(item: product)
						
						StockServerFactory.getStockServer().setStockLevel(product: product.name, stockLevel: product.stockLevel)
					}
                    break;
                }
            }
            displayStockTotal();
        }
    }
	
//	func undoStockLevel(data: [String: Int]) {
//		if let productName = data.keys.first {
//			if let stockLevel = data[productName] {
//				for nproduct in productStore.products {
//					if nproduct.name == productName {
//						nproduct.stockLevel = stockLevel
//					}
//				}
//				updateStockLevel(name: productName, level: stockLevel)
//			}
//		}
//		
//	}
	@objc func resetState() {
		productStore.resetState()
	}
	
    func displayStockTotal() {
//        let stockTotal = products.reduce(0,
//        combine: {(total, product) -> Int in return total + product.4});
//        totalStockLabel.text = "\(stockTotal) Products in Stock";
        let stockTotal = products.reduce(0) { (total, product) -> Int in
            return total + product.stockLevel
        }
        totalStockLabel.text = "\(stockTotal) Products in Stock";
		
		let finalTotals: (Int, Double) = productStore.products.reduce((0, 0.0)) { (totals, product) -> (Int, Double) in
			return (
				totals.0 + product.stockLevel,
				totals.1 + product.stockValue
			)
		}
		
//		var factory = StockTotalFactory.getFactory(curr: .GBP)
//		var totalAmount = factory.converter?.convertTotal(total: finalTotals.1)
//		var formatted = factory.formatter?.formatTotal(total: totalAmount!)
		//  通过外观模式，将这三行代码整合在一起
		let formatted = StockTotalFacade.formatCurrencyFormat(amount: finalTotals.1, currency: .EUR)
		
		totalStockLabel.text = "\(finalTotals.0) Products in Stock." + "Total Value: \(formatted!))"
    }
}


