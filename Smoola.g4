grammar Smoola;
	@members{

		class ErrorItem {
		   	public Integer line;
		   	public String error;
		   	ErrorItem(Integer line, String error) {
		   		this.line = line;
		   		this.error = error;
		   	}

		   	public Integer getLine(){return line;}
		}

		void print(Object obj){
	        System.out.println(obj);
		}

		void printSymbols(HashMap<String, SymbolTableItem> items){
	   		Iterator it = items.entrySet().iterator();
		    while (it.hasNext()) {
		        Map.Entry pair = (Map.Entry)it.next();
	        	System.out.println(pair.getKey());
	         	Iterator it2 =
	         		((SymbolTableClassItem)(pair.getValue())).getSymbolTable().getItems().entrySet().iterator();
			    while (it2.hasNext()) {
			        Map.Entry pair2 = (Map.Entry)it2.next();
			        System.out.printf("\t%s\n", pair2.getKey());
			    }
			}
		}

		void printErrors(ArrayList<ErrorItem> items){
			items.sort((o1, o2) -> o1.getLine().compareTo(o2.getLine()));
	   		for(ErrorItem item : items) {
	   			System.out.print(item.error);
	   		}
		}
	}

	@header {
		import ast.*;
		import ast.node.Program;
		import ast.node.declaration.*;
		import ast.node.expression.*;
		import ast.node.expression.Value.*;
		import ast.node.statement.*;
		import ast.Type.*;
		import ast.Type.ArrayType.*;
		import ast.Type.PrimitiveType.*;
		import ast.Type.UserDefinedType.*;
		import symbolTable.*;
		import java.util.Map;
		import java.util.Iterator;
		import java.util.Set;
		import java.util.HashMap;
		import java.util.ArrayList;
	}

	program:
		{ArrayList<ErrorItem> errors = new ArrayList<>();}
		program1 [new SymbolTable(), 0, errors]
		{
			errors = $program1.errors_;
			print($program1.error_count);
			if ($program1.synthesized_table.getItemsSize() == 0 || $program1.error_count > 0) {
				if ($program1.synthesized_table.getItemsSize() == 0) {
					// System.out.printf("Line:%d:No class exists in the program\n", $program1.start.getLine());
					errors.add(new ErrorItem(new Integer($program1.start.getLine()),
						String.format("Line:%d:No class exists in the program\n", $program1.start.getLine())));
				}
				printErrors(errors);
			} else {
				VisitorImpl visitor = new VisitorImpl();
				$program1.synthesized_type.accept(visitor);
			}
		}
	;
    program1 [SymbolTable inherited_table, int inherited_error_count, ArrayList<ErrorItem> errors] returns
    	[ArrayList<ErrorItem> errors_, Program synthesized_type,int error_count, SymbolTable synthesized_table]:
        {int index = 0; $synthesized_type = new Program();} mainClass [new SymbolTable(inherited_table)]
		{
			$synthesized_type.setMainClass($mainClass.synthesized_type);
			try {
        		if ($mainClass.synthesized_type == null) {
        			throw new Exception();
        		} //for What?!
        		$inherited_table.put(new SymbolTableClassItem($mainClass.synthesized_type.getName().getName(), null,
        			$mainClass.synthesized_table, $mainClass.start.getLine()));
        	}
        	catch(Exception e) {
        			
        	}
		} 
		(classDeclaration[$inherited_error_count ,index , new SymbolTable(inherited_table), $errors]
		 {
		 	$errors = $classDeclaration.errors_; 
		 	index = $classDeclaration.synthesized_index;
			$synthesized_type.addClass($classDeclaration.synthesized_type);
			 
    		$inherited_error_count = $classDeclaration.error_count;
    		//$synthesized_type.addClass($classDeclaration.synthesized_type);
    		try{
    			$inherited_table.put(new SymbolTableClassItem($classDeclaration.synthesized_type.getName().getName(), 
					(($classDeclaration.synthesized_type.getParentName() != null) ?
						$classDeclaration.synthesized_type.getParentName().getName() : null),
						$classDeclaration.synthesized_table, $classDeclaration.start.getLine()));
    		}catch(ItemAlreadyExistsException e){
    			// add class with new name
    			try{
    				// print("temp_" + $classDeclaration.synthesized_type.getName().getName() + Integer.toString(index++));
    				$inherited_table.put(new SymbolTableClassItem("temp_" +
    					$classDeclaration.synthesized_type.getName().getName() + Integer.toString(index++), 
						(($classDeclaration.synthesized_type.getParentName() != null) ?
						$classDeclaration.synthesized_type.getParentName().getName() : null),
						$classDeclaration.synthesized_table, $classDeclaration.start.getLine()));
    			} catch(ItemAlreadyExistsException e2){

    			}
    			$inherited_error_count++;
    			$errors.add(new ErrorItem(new Integer($classDeclaration.start.getLine()),
    				String.format("Line:%d:Redefinition of class %s\n", $classDeclaration.start.getLine(),
    				$classDeclaration.synthesized_type.getName().getName())));
    			// System.out.printf("Line:%d:Redefinition of class %s\n", $classDeclaration.start.getLine(), $classDeclaration.synthesized_type.getName().getName());
    		}
 
		 })*
		  {$synthesized_table = $inherited_table; $error_count = $inherited_error_count;}
        {
        	Iterator it = $synthesized_table.getItems().entrySet().iterator();
		    while (it.hasNext()) {
		        Map.Entry pair = (Map.Entry)it.next();
		        if (((SymbolTableClassItem)(pair.getValue())).getParentName() != null && ((SymbolTableClassItem)(pair.getValue())).getParentName() != "") {
		        	if (((SymbolTableClassItem)($synthesized_table.getInCurrentScope(((SymbolTableClassItem)(pair.getValue())).getParentName()))) != null) {
		        		((SymbolTableClassItem)(pair.getValue())).setParent(((SymbolTableClassItem)($synthesized_table.getInCurrentScope(((SymbolTableClassItem)(pair.getValue())).getParentName()))).getSymbolTable());
		        	}
		         	//((SymbolTableClassItem)(pair.getValue())).setParent();
		         	Iterator it2 = ((SymbolTableClassItem)(pair.getValue())).getSymbolTable().getItems().entrySet().iterator();
		         	ArrayList<SymbolTableItem> items = new ArrayList<>();
				    while (it2.hasNext()) {
				        Map.Entry pair2 = (Map.Entry)it2.next();
				        if (((SymbolTableClassItem)(pair.getValue())).getParentSymbolTable() != null && ((SymbolTableClassItem)(pair.getValue())).getParentSymbolTable().getItems().containsKey(pair2.getKey())) {
				        	if (pair2.getValue() instanceof SymbolTableMethodItem) {
				        		$error_count++;
				        		$errors.add(new ErrorItem(new Integer(((SymbolTableMethodItem)(pair2.getValue())).getLine()), String.format("Line:%d:Redefinition of method %s\n",
    								((SymbolTableMethodItem)(pair2.getValue())).getLine(), ((SymbolTableMethodItem)(pair2.getValue())).getName())));
				        		// System.out.printf("Line:%d:Redefinition of method ‬‬%s\n", ((SymbolTableMethodItem)(pair2.getValue())).getLine(), ((SymbolTableMethodItem)(pair2.getValue())).getName());
				        		items.add((SymbolTableMethodItem)(pair2.getValue()));
				        	} else {
				        		$error_count++;
				        		$errors.add(new ErrorItem(new Integer(((SymbolTableVariableItemBase)(pair2.getValue())).getLine()), String.format("Line:%d:Redefinition of variable %s\n",
    								((SymbolTableVariableItemBase)(pair2.getValue())).getLine(), ((SymbolTableVariableItemBase)(pair2.getValue())).getName())));
				        		// System.out.printf("Line:%d:Redefinition of variable ‬‬%s\n", ((SymbolTableVariableItemBase)(pair2.getValue())).getLine(), ((SymbolTableVariableItemBase)(pair2.getValue())).getName());
				        		items.add((SymbolTableVariableItemBase)(pair2.getValue()));
				        	}
				        }
					}
					for(SymbolTableItem element : items) {
						if (element instanceof SymbolTableMethodItem) {
			        		try{
			        			((SymbolTableClassItem)(pair.getValue())).putItem(new SymbolTableMethodItem("temp_" + ((SymbolTableMethodItem)element).getName() + Integer.toString(index++),
			        				((SymbolTableMethodItem)element).getArgTypes(), ((SymbolTableMethodItem)element).getLine()));
			        		}catch(ItemAlreadyExistsException e3){

			        		}
			        		((SymbolTableClassItem)(pair.getValue())).removeItem(((SymbolTableMethodItem)element).getKey());
		        		} else {
		        			try{
			        			((SymbolTableClassItem)(pair.getValue())).putItem(new SymbolTableVariableItemBase("temp_" + ((SymbolTableVariableItemBase)element).getName() + Integer.toString(index++),
			        				((SymbolTableVariableItemBase)element).getType(), index++, ((SymbolTableVariableItemBase)element).getLine()));
			        		}catch(ItemAlreadyExistsException e3){
			        			
			        		}
			        		((SymbolTableClassItem)(pair.getValue())).removeItem(((SymbolTableVariableItemBase)element).getKey());
		        		}
					}
					//printSymbols($synthesized_table.getItems());
		    	}
        	}
        } 
		  EOF {$errors_ = $errors;}
    ;
    mainClass [SymbolTable inherited_table] returns [ClassDeclaration synthesized_type, SymbolTable synthesized_table]:
        // name should be checked later
        'class' name = ID 
		{
			$synthesized_type = new ClassDeclaration(new Identifier($name.getText()), null);
		}
		'{' 'def' mainMethod = ID '(' ')' ':' 'int' '{'  statements 'return' expression ';' '}' '}'
		{
        	try {
        		if ($mainMethod.getText() != null) {
        			$inherited_table.put(new SymbolTableMethodItem($mainMethod.getText(),null,$mainMethod.line));	
        		}	
        	}
        	catch(Exception e) {
        		
        	}
			MethodDeclaration b = new MethodDeclaration(new Identifier($mainMethod.getText()));
			b.setReturnType(new IntType());
			for (int i =0 ; i < $statements.synthesized_type.size(); ++i){
				b.addStatement($statements.synthesized_type.get(i));
			}
			b.setReturnValue($expression.synthesized_type);
			$synthesized_type.addMethodDeclaration(b);
			$synthesized_table = $inherited_table;
		}
    ;
    classDeclaration [int inherited_error_count, int inherited_index, SymbolTable inherited_table, ArrayList<ErrorItem> errors] returns [ArrayList<ErrorItem> errors_, int synthesized_index,int error_count, ClassDeclaration synthesized_type, SymbolTable synthesized_table]:
        'class' name = ID ('extends' father_name = ID)? 
		{$synthesized_type = new ClassDeclaration(new Identifier($name.getText()), (($father_name != null) ? new Identifier($father_name.getText()) : null));}
		'{' (varDeclaration
		{
			try {
				if ($varDeclaration.synthesized_type != null) {
					$synthesized_type.addVarDeclaration($varDeclaration.synthesized_type);
					$inherited_table.put(new SymbolTableVariableItemBase($varDeclaration.synthesized_type.getIdentifier().getName(), $varDeclaration.synthesized_type.getType(), $inherited_index++, $varDeclaration.start.getLine()));
				}
			}
			catch(ItemAlreadyExistsException e) {
				$inherited_error_count++;
				try{
					//print("temp_" + $varDeclaration.synthesized_type.getIdentifier().getName() + Integer.toString($inherited_index++));
					$inherited_table.put(new SymbolTableVariableItemBase("temp_" + $varDeclaration.synthesized_type.getIdentifier().getName() + Integer.toString($inherited_index++), $varDeclaration.synthesized_type.getType(), $inherited_index++, $varDeclaration.start.getLine()));
				} catch(ItemAlreadyExistsException e2){

				}
				// System.out.printf("Line:%d:Redefinition of variable ‬‬%s\n", $varDeclaration.start.getLine(), $varDeclaration.synthesized_type.getIdentifier().getName());	
				$errors.add(new ErrorItem(new Integer($varDeclaration.start.getLine()), String.format("Line:%d:Redefinition of variable %s\n",
    								$varDeclaration.start.getLine(), $varDeclaration.synthesized_type.getIdentifier().getName())));
			}
		})* 
		(methodDeclaration[$inherited_error_count, $inherited_index, $inherited_table, $errors]
		{
			$errors = $methodDeclaration.errors_;
			$inherited_index = $methodDeclaration.synthesized_index;
			$inherited_error_count = $methodDeclaration.error_count;
			try {
				if ($methodDeclaration.synthesized_type != null) {
					$synthesized_type.addMethodDeclaration($methodDeclaration.synthesized_type);
					$inherited_table.put(new SymbolTableMethodItem($methodDeclaration.synthesized_type.getName().getName(),$methodDeclaration.synthesized_type.getArgTypes(), $methodDeclaration.start.getLine()));	
				}	
			}
			catch(ItemAlreadyExistsException e) {
				$inherited_error_count++;
				try{
					// print("temp_" + $methodDeclaration.synthesized_type.getName().getName() + Integer.toString($inherited_index++));
					$inherited_table.put(new SymbolTableMethodItem("temp_" + $methodDeclaration.synthesized_type.getName().getName() + Integer.toString($inherited_index++),$methodDeclaration.synthesized_type.getArgTypes(), $methodDeclaration.start.getLine()));
				}catch(ItemAlreadyExistsException e2){

				}
				// System.out.printf("Line:%d:Redefinition of method ‬‬%s\n", $methodDeclaration.start.getLine(), $methodDeclaration.synthesized_type.getName().getName());	
				$errors.add(new ErrorItem(new Integer($methodDeclaration.start.getLine()), String.format("Line:%d:Redefinition of method %s\n",
    								$methodDeclaration.start.getLine(), $methodDeclaration.synthesized_type.getName().getName())));
			}
		})* '}'
		{
			$synthesized_table = $inherited_table;
			$error_count = $inherited_error_count;
			$synthesized_index = $inherited_index;
			$errors_ = $errors;
		}
		
    ;
    varDeclaration returns [VarDeclaration synthesized_type]:
        'var' ID ':' type ';' 
		{$synthesized_type = new VarDeclaration(new Identifier($ID.getText()),$type.synthesized_type);}
    ;
    methodDeclaration[int inherited_error_count, int inherited_index, SymbolTable inherited_table, ArrayList<ErrorItem> errors] returns [ArrayList<ErrorItem> errors_, int synthesized_index,int error_count, SymbolTable synthesized_table,MethodDeclaration synthesized_type]:
        {$synthesized_table = new SymbolTable();}'def' name = ID {$synthesized_type = new MethodDeclaration(new Identifier($name.getText()));}
		('(' ')' | ('(' n1 = ID ':' type 
		{
			$synthesized_type.addArg(new VarDeclaration(new Identifier($n1.getText()),$type.synthesized_type));
			try{
				$synthesized_table.put(new SymbolTableVariableItemBase($n1.getText(), $type.synthesized_type, $inherited_index++, $n1.line));
			}catch(ItemAlreadyExistsException ew){
				$inherited_error_count++;
    			try{
    				// print("temp_" + $varDeclaration.synthesized_type.getIdentifier().getName() + Integer.toString($inherited_index++));
    				$synthesized_table.put(new SymbolTableVariableItemBase("temp_" + $n1.getText() + Integer.toString($inherited_index++),
    					$type.synthesized_type, $inherited_index++, $n1.line));
    			}catch(ItemAlreadyExistsException e2){

    			}
    			// System.out.printf("Line:%d:Redefinition of variable ‬‬%s\n", $n1.line, $n1.getText());
    			$errors.add(new ErrorItem($n1.line, String.format("Line:%d:Redefinition of variable %s\n", $n1.line, $n1.getText())));
			}
		}
		(',' n2 = ID ':' type 
		{
			$synthesized_type.addArg(new VarDeclaration(new Identifier($n2.getText()),$type.synthesized_type));
			try{
				$synthesized_table.put(new SymbolTableVariableItemBase($n2.getText(), $type.synthesized_type, $inherited_index++, $n2.line));
			}catch(ItemAlreadyExistsException ew){
				$inherited_error_count++;
    			try{
    				// print("temp_" + $varDeclaration.synthesized_type.getIdentifier().getName() + Integer.toString($inherited_index++));
    				$synthesized_table.put(new SymbolTableVariableItemBase("temp_" + $n2.getText() + Integer.toString($inherited_index++),
    					$type.synthesized_type, $inherited_index++, $n2.line));
    			}catch(ItemAlreadyExistsException e2){

    			}
    			// System.out.printf("Line:%d:Redefinition of variable ‬‬%s\n", $n2.line, $n2.getText());
    			$errors.add(new ErrorItem($n2.line, String.format("Line:%d:Redefinition of variable %s\n", $n2.line, $n2.getText())));
			}
		})* ')'))
		':' type {$synthesized_type.setReturnType($type.synthesized_type);} '{'  
		(varDeclaration
		{	
			try {
    			if ($varDeclaration.synthesized_type != null) {
					$synthesized_type.addLocalVar($varDeclaration.synthesized_type);
    				$synthesized_table.put(new SymbolTableVariableItemBase($varDeclaration.synthesized_type.getIdentifier().getName(), $varDeclaration.synthesized_type.getType(), $inherited_index++, $varDeclaration.start.getLine()));
    			}
    		}
    		catch(Exception e) {
    			$inherited_error_count++;
    			try{
    				// print("temp_" + $varDeclaration.synthesized_type.getIdentifier().getName() + Integer.toString($inherited_index++));
    				$synthesized_table.put(new SymbolTableVariableItemBase("temp_" + $varDeclaration.synthesized_type.getIdentifier().getName() + Integer.toString($inherited_index++), $varDeclaration.synthesized_type.getType(), $inherited_index++, $varDeclaration.start.getLine()));
    			}catch(ItemAlreadyExistsException e2){

    			}
    			// System.out.printf("Line:%d:Redefinition of variable ‬‬%s\n", $varDeclaration.start.getLine(), $varDeclaration.synthesized_type.getIdentifier().getName());	
    			$errors.add(new ErrorItem($varDeclaration.start.getLine(), String.format("Line:%d:Redefinition of variable %s\n",
    				$varDeclaration.start.getLine(), $varDeclaration.synthesized_type.getIdentifier().getName())));
    		}
		}
		)* 
		statements 
		{
			for (int i =0 ; i < $statements.synthesized_type.size(); ++i){
				$synthesized_type.addStatement($statements.synthesized_type.get(i));
			}
			$inherited_error_count += $statements.error_count;
			for(ErrorItem it : $statements.errors){
				if(it != null)
					$errors.add(it);
			}
		}
		'return' expression 
		{
			$synthesized_type.setReturnValue($expression.synthesized_type);
			$synthesized_table.pop();
		} ';' '}'
		{$error_count = $inherited_error_count; $synthesized_index = $inherited_index; $errors_ = $errors;}
    ;
    statements returns [ArrayList<Statement> synthesized_type,int error_count, ArrayList<ErrorItem> errors]:
		{
			$error_count = 0;
			$errors = new ArrayList<ErrorItem>();
			$synthesized_type = new ArrayList<Statement>();
		}
		(statement 
		{
			$synthesized_type.add($statement.synthesized_type);
			$error_count += $statement.error_count;
			$errors.add($statement.error_item);
		}
		)*
    ;
    statement returns [Statement synthesized_type,int error_count, ErrorItem error_item]:
		{$error_count = 0;}
		(
        statementBlock 
		{
			$synthesized_type = $statementBlock.synthesized_type;
		} |
        statementCondition
		{
			$synthesized_type = $statementCondition.synthesized_type;
		} |
        statementLoop
		{
			$synthesized_type = $statementLoop.synthesized_type;
		} |
        statementWrite
		{
			$synthesized_type = $statementWrite.synthesized_type;
		} |
        statementAssignment
		{
			$synthesized_type = $statementAssignment.synthesized_type;
			$error_count = $statementAssignment.error_count;
			$error_item = $statementAssignment.error_item;
		}
		)
    ;
    statementBlock returns [Block synthesized_type]:
        '{' {$synthesized_type = new Block();}statements
		{
			for (int i =0 ; i < $statements.synthesized_type.size(); ++i){
				$synthesized_type.addStatement($statements.synthesized_type.get(i));
			}
		} '}'
    ;

    statementCondition returns [Conditional synthesized_type]:
        'if' '('expression')' 'then' s1 = statement 
		{
			$synthesized_type = new Conditional($expression.synthesized_type, $s1.synthesized_type);
		}
		('else' statement 
		{$synthesized_type.setAlternativeBody($statement.synthesized_type);}
		)?
    ;
    statementLoop returns [While synthesized_type]:
        'while' '(' expression ')' statement 
		{$synthesized_type = new While($expression.synthesized_type,$statement.synthesized_type);}
    ;
    statementWrite returns [Write synthesized_type]:
        'writeln(' expression ')' ';' 
		{$synthesized_type = new Write($expression.synthesized_type);} 
    ;
    statementAssignment returns [Assign synthesized_type,int error_count, ErrorItem error_item]:
        expression ';' 
		{
			$synthesized_type = new Assign(((BinaryExpression)$expression.synthesized_type).getLeft(),((BinaryExpression)$expression.synthesized_type).getRight());
			$error_count = $expression.error_count;
			$error_item = $expression.error_item;
		}
    ;

    expression returns [Expression synthesized_type,int error_count, ErrorItem error_item]:
		expressionAssignment 
		{
			$synthesized_type = $expressionAssignment.synthesized_type;
			$error_count = $expressionAssignment.error_count;
			$error_item = $expressionAssignment.error_item;
		}
	;

    expressionAssignment returns [Expression synthesized_type,int error_count, ErrorItem error_item]:
		expressionOr '=' expressionAssignment 
		{
			$synthesized_type = new BinaryExpression($expressionOr.synthesized_type,$expressionAssignment.synthesized_type,BinaryOperator.assign);
			$error_count = $expressionAssignment.error_count;
			$error_item = $expressionAssignment.error_item;

		}
	    |	expressionOr 
		{
			$synthesized_type = $expressionOr.synthesized_type;
			$error_count = $expressionOr.error_count;
			$error_item = $expressionOr.error_item;
		}
	;

    expressionOr returns [Expression synthesized_type,int error_count, ErrorItem error_item]:
		expressionAnd expressionOrTemp[$expressionAnd.synthesized_type] 
		{
			$synthesized_type = $expressionOrTemp.synthesized_type;
			$error_count = $expressionAnd.error_count;
			$error_item = $expressionAnd.error_item;
		}
	;

    expressionOrTemp [Expression inherited_type] returns [Expression synthesized_type]:
		'||' expressionAnd expressionOrTemp[$expressionAnd.synthesized_type] 
		{$synthesized_type = new BinaryExpression($inherited_type,$expressionOrTemp.synthesized_type,BinaryOperator.or);}
	    | {$synthesized_type = $inherited_type;}
	;

    expressionAnd returns [Expression synthesized_type,int error_count, ErrorItem error_item]:
		expressionEq expressionAndTemp[$expressionEq.synthesized_type]
		{
			$synthesized_type = $expressionAndTemp.synthesized_type;
			$error_count = $expressionEq.error_count;
			$error_item = $expressionEq.error_item;
		}
	;

    expressionAndTemp [Expression inherited_type] returns [Expression synthesized_type]:
		'&&' expressionEq expressionAndTemp[$expressionEq.synthesized_type]
		{$synthesized_type = new BinaryExpression($inherited_type,$expressionAndTemp.synthesized_type,BinaryOperator.and);}
	    | {$synthesized_type = $inherited_type;}
	;

    expressionEq returns [Expression synthesized_type,int error_count, ErrorItem error_item]:
		expressionCmp expressionEqTemp[$expressionCmp.synthesized_type] 
		{
			$synthesized_type = $expressionEqTemp.synthesized_type;
			$error_count = $expressionCmp.error_count;
			$error_item = $expressionCmp.error_item;
		}
	;

    expressionEqTemp [Expression inherited_type] returns [Expression synthesized_type]:
		{BinaryOperator b;}('=='{b = BinaryOperator.eq;}|'<>'{b = BinaryOperator.neq;}) expressionCmp expressionEqTemp[$expressionCmp.synthesized_type]
		{$synthesized_type = new BinaryExpression($inherited_type,$expressionEqTemp.synthesized_type,b);} 
	    | {$synthesized_type = $inherited_type;} 
	;

    expressionCmp returns [Expression synthesized_type,int error_count, ErrorItem error_item]:
		expressionAdd expressionCmpTemp[$expressionAdd.synthesized_type]
		{
			$synthesized_type = $expressionCmpTemp.synthesized_type;
			$error_count = $expressionAdd.error_count;
			$error_item = $expressionAdd.error_item;
		}
	;

    expressionCmpTemp [Expression inherited_type] returns [Expression synthesized_type]:
		{BinaryOperator b;}('<'{b = BinaryOperator.lt;} | '>'{b = BinaryOperator.gt;}) expressionAdd expressionCmpTemp [$expressionAdd.synthesized_type]
		{$synthesized_type = new BinaryExpression($inherited_type,$expressionCmpTemp.synthesized_type,b);}
	    | {$synthesized_type = $inherited_type;} 
	;

    expressionAdd returns [Expression synthesized_type,int error_count, ErrorItem error_item]:
		expressionMult expressionAddTemp[$expressionMult.synthesized_type]
		{
			$synthesized_type = $expressionAddTemp.synthesized_type;
			$error_count = $expressionMult.error_count;
			$error_item = $expressionMult.error_item;
		}
	;

    expressionAddTemp [Expression inherited_type] returns [Expression synthesized_type]:
		{BinaryOperator b;}('+'{b = BinaryOperator.add;} | '-'{b = BinaryOperator.sub;}) expressionMult expressionAddTemp[$expressionMult.synthesized_type]
		{$synthesized_type = new BinaryExpression($inherited_type,$expressionAddTemp.synthesized_type,b);}
	    | {$synthesized_type = $inherited_type;} 
	;

    expressionMult returns [Expression synthesized_type,int error_count, ErrorItem error_item]:
		expressionUnary expressionMultTemp[$expressionUnary.synthesized_type]
		{
			$synthesized_type = $expressionMultTemp.synthesized_type;
			$error_count = $expressionUnary.error_count;
			$error_item = $expressionUnary.error_item;
		}
	;

    expressionMultTemp [Expression inherited_type] returns [Expression synthesized_type]:
		{BinaryOperator b;}('*'{b = BinaryOperator.mult;} | '/'{b = BinaryOperator.div;}) expressionUnary expressionMultTemp[$expressionUnary.synthesized_type]
		{
			$synthesized_type = new BinaryExpression($inherited_type,$expressionMultTemp.synthesized_type,b);
		}
	    | {$synthesized_type = $inherited_type;} 
	;

    expressionUnary returns [Expression synthesized_type,int error_count, ErrorItem error_item]:
		{UnaryOperator u;} ('!'{u = UnaryOperator.not;} | '-'{u = UnaryOperator.minus;}) expressionUnary 
		{ 
			$synthesized_type = new UnaryExpression(u,$expressionUnary.synthesized_type);
			$error_count = 0;
			$error_item = null;
		}
	    |	
		expressionMem 
		{
			$synthesized_type = $expressionMem.synthesized_type;
			$error_count = $expressionMem.error_count;
			$error_item = $expressionMem.error_item;
		}
	;

    expressionMem returns [Expression synthesized_type,int error_count, ErrorItem error_item]:
		expressionMethods expressionMemTemp[$expressionMethods.synthesized_type]
		{
			$synthesized_type = $expressionMemTemp.synthesized_type;
			$error_count = $expressionMethods.error_count;
			$error_item = $expressionMethods.error_item;
		}
	;

    expressionMemTemp [Expression inherited_type] returns [Expression synthesized_type]:
		'[' expression ']' 
		{$synthesized_type = new ArrayCall($inherited_type,$expression.synthesized_type);}
	    | {$synthesized_type = $inherited_type;}
	;
	expressionMethods returns [Expression synthesized_type,int error_count, ErrorItem error_item]:
	    expressionOther expressionMethodsTemp[$expressionOther.synthesized_type]
		{
			$synthesized_type = $expressionMethodsTemp.synthesized_type;
			$error_count = $expressionOther.error_count;
			$error_item = $expressionOther.error_item;
		}
	;
	expressionMethodsTemp [Expression inherited_type] returns [Expression synthesized_type]:
	    '.' (ID '(' ')' 
		{
			$synthesized_type = new MethodCall($inherited_type,new Identifier($ID.getText()));
		}
		| ID 
		{
			$synthesized_type = new MethodCall($inherited_type,new Identifier($ID.getText()));
		}
		'(' (expression
		{
			((MethodCall)$synthesized_type).addArg($expression.synthesized_type);
		} 
		(',' expression
		{
			((MethodCall)$synthesized_type).addArg($expression.synthesized_type);
		})*
		) ')' | 'length'
		{
			$synthesized_type = new Length($inherited_type);
		})
		expressionMethodsTemp[$synthesized_type]
		{
			$synthesized_type = $expressionMethodsTemp.synthesized_type;
		}
	    | {$synthesized_type = $inherited_type;}
	;
    expressionOther returns [Expression synthesized_type,int error_count, ErrorItem error_item]:
		{$error_count = 0; $error_item = null;}
		(
			CONST_NUM {$synthesized_type = new IntValue(Integer.parseInt($CONST_NUM.getText()), new IntType());}
        |	CONST_STR {$synthesized_type = new StringValue($CONST_STR.getText(),new StringType());}
        |   'new ' 'int' '[' index = CONST_NUM ']' 
		{
			$synthesized_type = new NewArray();
			((NewArray)$synthesized_type).setExpression(new IntValue(Integer.parseInt($index.text),new IntType()));
			if (Integer.parseInt($index.text) <= 0) {
        		$error_count = 1;
        		$error_item = new ErrorItem($index.getLine(), String.format("Line:%d:Array length should not be zero or negative\n", $index.getLine()));
        		// System.out.printf("Line:%d:Array length should not be zero or negative\n", $index.getLine());
        	}
		}
        |   'new ' ID '(' ')'
		{
			$synthesized_type = new NewClass(new Identifier($ID.getText()));
		}
        |   'this' {$synthesized_type = new This();}
        |   t = 'true' {$synthesized_type = new BooleanValue(Boolean.parseBoolean($t.getText()),new BooleanType());}
        |   f = 'false' {$synthesized_type = new BooleanValue(Boolean.parseBoolean($f.getText()),new BooleanType());}
        |	ID 
		{$synthesized_type = new Identifier($ID.getText());}
        |   ID '[' expression ']' 
		{$synthesized_type = new ArrayCall(new Identifier($ID.getText()),$expression.synthesized_type);}
        |	'(' expression ')'
		{$synthesized_type = $expression.synthesized_type;}
		)
	;
	type returns[Type synthesized_type]:
	    'int' {$synthesized_type = new IntType();}|
	    'boolean' {$synthesized_type = new BooleanType();}|
	    'string' {$synthesized_type = new StringType();}|
	    'int' '[' ']' {$synthesized_type = new ArrayType();}|
	    ID {$synthesized_type = new UserDefinedType();((UserDefinedType)$synthesized_type).setName(new Identifier($ID.getText()));} // Class declration? 
	;
    CONST_NUM:
		[0-9]+
	;

    CONST_STR:
		'"' ~('\r' | '\n' | '"')* '"'
	;
    NL:
		'\r'? '\n' -> skip
	;

    ID:
		[a-zA-Z_][a-zA-Z0-9_]*
	;

    COMMENT:
		'#'(~[\r\n])* -> skip
	;

    WS:
    	[ \t] -> skip
    ;
