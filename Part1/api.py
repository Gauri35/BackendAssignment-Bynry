#code with changes implemented 
#explaination via comments in the code

@app.route('/api/products', methods=['POST'])
@jwt_required()   #this enforces authentication using JWT 
def create_product():
    data = request.json

    logging.info(f"User: {get_jwt_identity()}") #logging the user who is creating the product

    try: 

        #input validation for required fields
        required_fields = ['name', 'sku', 'price', 'initial_quantity', 'warehouse_id']
        missing_fields = [field for field in required_fields if field not in data]
        if missing_fields: 
            return jsonify({"error": f"Missing required fields: {', '.join(missing_fields)}"}), 400

        #support for multiple warehouses -> warehouses must be a list of {warehouse_id, initial_quantity}
        if not isinstance(data['warehouses'], list) or not data['warehouses']:
            return jsonify({"error": "warehouses must be a non-empty list"}), 400

        #price validation
        price = round(Decimal(str(data['price'])), 2)
        if price <= 0:
            return jsonify({"error": "Price must be greater than 0"}), 400

        #SKU validation
        existing_product = Product.query.filter_by(sku=data['sku']).first()
        if existing_product:
            return jsonify({"error": "SKU already exists"}), 400

        #warehouse validation
        for entry in data['warehouses']:
            #both field, warehouse_id and initial_quantity are required
            if not isinstance(entry, dict) or 'warehouse_id' not in entry or 'initial_quantity' not in entry:
                return jsonify({"error": "Invalid warehouse entry"}), 400

            #check if warehouse exists in the database
            warehouse = Warehouse.query.get(entry['warehouse_id'])
            if not warehouse:
                return jsonify({"error": "Invalid warehouse ID"}), 400
            
            #validate initial quantity
            if not isinstance(entry['initial_quantity'], int) or entry['initial_quantity'] < 0:
                return jsonify({"error": "Initial quantity must be a non-negative"}), 400

        #transaction handling for product and inventory creation
        with db.session.begin():
            
            # Create new product
            product = Product(
            name=data['name'],
            sku=data['sku'],
            price=data['price']
            )

            db.session.add(product)
            db.session.commit()

            # Update inventory count

            for entry in data['warehouses']:

                warehouse = Warehouse.query.get(entry['warehouse_id'])
                inventory = Inventory(
                product_id=product.id,
                warehouse_id=warehouse.id,
                quantity=entry['initial_quantity']
                )

                db.session.add(inventory)
                db.session.commit()

            return jsonify({"message": "Product created", "product_id": product.id}), 200

    except IntegrityError as e:
        db.session.rollback()
        logging.error(f"Database integrity error: {str(e)}")
        return jsonify({"error": f"Database integrity error: {str(e)}"}), 500
    except ValueError as e:
        db.session.rollback()
        logging.error(f"Invalid value: {str(e)}")
        return jsonify({"error": f"Invalid value: {str(e)}"}), 400
    except Exception as e:
        db.session.rollback()
        logging.error(f"Unexpected error: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500




 
    