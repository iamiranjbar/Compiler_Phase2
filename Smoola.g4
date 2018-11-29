grammar Smoola;
	@members{
	   void print(Object obj){
	        System.out.println(obj);
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
	}

	program:
		program1 [new SymbolTable(), 0]
		{
			print($program1.error_count);
			if ($program1.synthesized_table.getItemsSize() == 0 || $program1.error_count > 0) {
				if ($program1.synthesized_table.getItemsSize() == 0) {
					System.out.printf("Line:%d:No class exists in the program\n", $program1.start.getLine());	
				}
			} else {
				VisitorImpl visitor = new VisitorImpl();
				$program1.synthesized_type.accept(visitor);
			}
		}
	;
    program1 [SymbolTable inherited_table, int inherited_error_count] returns [Program synthesized_type,int error_count, SymbolTable synthesized_table]:
        {$synthesized_type = new Program();} mainClass [new SymbolTable(inherited_table)]
		{
			$synthesized_type.setMainClass($mainClass.synthesized_type);
			try {
        		if ($mainClass.synthesized_type == null) {
        			throw new Exception();
        		} //for What?!
        		$inherited_table.put(new SymbolTableClassItem($mainClass.synthesized_type.getName().getName(), null, $mainClass.synthesized_table, $mainClass.start.getLine()));
        	}
        	catch(Exception e) {
        			
        	}
		} 
		(classDeclaration[inherited_error_count ,0, new SymbolTable(inherited_table)]
		 {
			 $synthesized_type.addClass($classDeclaration.synthesized_type);
			         	{
        		$inherited_error_count = $inherited_error_count + $classDeclaration.error_count;
        		$synthesized_type.addClass($classDeclaration.synthesized_type);
        		try{
        			$inherited_table.put(new SymbolTableClassItem($classDeclaration.synthesized_type.getName().getName(), 
						(($classDeclaration.synthesized_type.getParentName() != null) ? $classDeclaration.synthesized_type.getParentName().getName() : null),
						$classDeclaration.synthesized_table, $classDeclaration.start.getLine()));
        		}catch(ItemAlreadyExistsException e){
        			// add class with new name
        			$inherited_error_count++;
        			System.out.printf("Line:%d:Redefinition of class %s\n", $classDeclaration.start.getLine(), $classDeclaration.synthesized_type.getName().getName());
        		}
        	}
		 })*
		  {$synthesized_table = $inherited_table; $error_count = $inherited_error_count;}
        {
        	Iterator it = $synthesized_table.getItems().entrySet().iterator();
		    while (it.hasNext()) {
		        Map.Entry pair = (Map.Entry)it.next();
		        if (((SymbolTableClassItem)(pair.getValue())).getParentName() != null && ((SymbolTableClassItem)(pair.getValue())).getParentName() != "") {
		         	((SymbolTableClassItem)(pair.getValue())).setParent(((SymbolTableClassItem)($synthesized_table.getInCurrentScope(((SymbolTableClassItem)(pair.getValue())).getParentName()))).getSymbolTable());
		         	Iterator it2 = ((SymbolTableClassItem)(pair.getValue())).getSymbolTable().getItems().entrySet().iterator();
				    while (it2.hasNext()) {
				        Map.Entry pair2 = (Map.Entry)it2.next();
				        if (((SymbolTableClassItem)(pair.getValue())).getParentSymbolTable().getItems().containsKey(pair2.getKey())) {
				        	if (pair2.getValue() instanceof SymbolTableMethodItem) {
				        		$error_count++;
				        		System.out.printf("Line:%d:Redefinition of method ‬‬%s\n", ((SymbolTableMethodItem)(pair2.getValue())).getLine(), ((SymbolTableMethodItem)(pair2.getValue())).getName());
				        	} else {
				        		$error_count++;
				        		System.out.printf("Line:%d:Redefinition of variable ‬‬%s\n", ((SymbolTableVariableItemBase)(pair2.getValue())).getLine(), ((SymbolTableVariableItemBase)(pair2.getValue())).getName());
				        	}
				        }
					}
		    	}
        	}
        }
		  EOF
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
    classDeclaration [int inherited_error_count, int inherited_index, SymbolTable inherited_table] returns [int error_count, ClassDeclaration synthesized_type, SymbolTable synthesized_table]:
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
				System.out.printf("Line:%d:Redefinition of variable ‬‬%s\n", $varDeclaration.start.getLine(), $varDeclaration.synthesized_type.getIdentifier().getName());	
			}
		})* 
		(methodDeclaration[$inherited_error_count, $inherited_index, $inherited_table]
		{
			$inherited_error_count = $inherited_error_count + $methodDeclaration.error_count;
			try {
				if ($methodDeclaration.synthesized_type != null) {
					$synthesized_type.addMethodDeclaration($methodDeclaration.synthesized_type);
					$inherited_table.put(new SymbolTableMethodItem($methodDeclaration.synthesized_type.getName().getName(),/*$methodDeclaration.synthesized_type.getArgs()*/null, $methodDeclaration.start.getLine()));	
				}	
			}
			catch(ItemAlreadyExistsException e) {
				$inherited_error_count++;
				System.out.printf("Line:%d:Redefinition of method ‬‬%s\n", $methodDeclaration.start.getLine(), $methodDeclaration.synthesized_type.getName().getName());	
			}
		})* '}' {$synthesized_table = $inherited_table; $error_count = $inherited_error_count;}
		
    ;
    varDeclaration returns [VarDeclaration synthesized_type]:
        'var' ID ':' type ';' 
		{$synthesized_type = new VarDeclaration(new Identifier($ID.getText()),$type.synthesized_type);}
    ;
    methodDeclaration[int inherited_error_count, int inherited_index, SymbolTable inherited_table] returns [int error_count, SymbolTable synthesized_table,MethodDeclaration synthesized_type]:
        {$synthesized_table = new SymbolTable();}'def' name = ID {$synthesized_type = new MethodDeclaration(new Identifier($name.getText()));}
		('(' ')' | ('(' n1 = ID ':' type {$synthesized_type.addArg(new VarDeclaration(new Identifier($n1.getText()),$type.synthesized_type));}
		(',' n2 = ID ':' type {$synthesized_type.addArg(new VarDeclaration(new Identifier($n2.getText()),$type.synthesized_type));})* ')'))
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
    			System.out.printf("Line:%d:Redefinition of variable ‬‬%s\n", $varDeclaration.start.getLine(), $varDeclaration.synthesized_type.getIdentifier().getName());	
    		}
		}
		)* 
		statements 
		{
			for (int i =0 ; i < $statements.synthesized_type.size(); ++i){
				$synthesized_type.addStatement($statements.synthesized_type.get(i));
			}
			$inherited_error_count += $statements.error_count;
		}
		'return' expression 
		{
			$synthesized_type.setReturnValue($expression.synthesized_type);
			$synthesized_table.pop();
		} ';' '}'
		{$error_count = $inherited_error_count;}
    ;
    statements returns [ArrayList<Statement> synthesized_type,int error_count]:
		{
			$error_count = 0;
			$synthesized_type = new ArrayList<Statement>();
		}
		(statement 
		{
			$synthesized_type.add($statement.synthesized_type);
			$error_count += $statement.error_count;
		}
		)*
    ;
    statement returns [Statement synthesized_type,int error_count]:
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
    statementAssignment returns [Assign synthesized_type,int error_count]:
        expression ';' 
		{
			$synthesized_type = new Assign(((BinaryExpression)$expression.synthesized_type).getLeft(),((BinaryExpression)$expression.synthesized_type).getRight());
			$error_count = $expression.error_count;
		}
    ;

    expression returns [Expression synthesized_type,int error_count]:
		expressionAssignment 
		{
			$synthesized_type = $expressionAssignment.synthesized_type;
			$error_count = $expressionAssignment.error_count;
		}
	;

    expressionAssignment returns [Expression synthesized_type,int error_count]:
		expressionOr '=' expressionAssignment 
		{
			$synthesized_type = new BinaryExpression($expressionOr.synthesized_type,$expressionAssignment.synthesized_type,BinaryOperator.assign);
			$error_count = $expressionAssignment.error_count;
		}
	    |	expressionOr 
		{
			$synthesized_type = $expressionOr.synthesized_type;
			$error_count = $expressionOr.error_count;
		}
	;

    expressionOr returns [Expression synthesized_type,int error_count]:
		expressionAnd expressionOrTemp[$expressionAnd.synthesized_type] 
		{
			$synthesized_type = $expressionOrTemp.synthesized_type;
			$error_count = $expressionAnd.error_count;
		}
	;

    expressionOrTemp [Expression inherited_type] returns [Expression synthesized_type]:
		'||' expressionAnd expressionOrTemp[$expressionAnd.synthesized_type] 
		{$synthesized_type = new BinaryExpression($inherited_type,$expressionOrTemp.synthesized_type,BinaryOperator.or);}
	    | {$synthesized_type = $inherited_type;}
	;

    expressionAnd returns [Expression synthesized_type,int error_count]:
		expressionEq expressionAndTemp[$expressionEq.synthesized_type]
		{
			$synthesized_type = $expressionAndTemp.synthesized_type;
			$error_count = $expressionEq.error_count;
		}
	;

    expressionAndTemp [Expression inherited_type] returns [Expression synthesized_type]:
		'&&' expressionEq expressionAndTemp[$expressionEq.synthesized_type]
		{$synthesized_type = new BinaryExpression($inherited_type,$expressionAndTemp.synthesized_type,BinaryOperator.and);}
	    | {$synthesized_type = $inherited_type;}
	;

    expressionEq returns [Expression synthesized_type,int error_count]:
		expressionCmp expressionEqTemp[$expressionCmp.synthesized_type] 
		{
			$synthesized_type = $expressionEqTemp.synthesized_type;
			$error_count = $expressionCmp.error_count;
		}
	;

    expressionEqTemp [Expression inherited_type] returns [Expression synthesized_type]:
		{BinaryOperator b;}('=='{b = BinaryOperator.eq;}|'<>'{b = BinaryOperator.neq;}) expressionCmp expressionEqTemp[$expressionCmp.synthesized_type]
		{$synthesized_type = new BinaryExpression($inherited_type,$expressionEqTemp.synthesized_type,b);} 
	    | {$synthesized_type = $inherited_type;} 
	;

    expressionCmp returns [Expression synthesized_type,int error_count]:
		expressionAdd expressionCmpTemp[$expressionAdd.synthesized_type]
		{
			$synthesized_type = $expressionCmpTemp.synthesized_type;
			$error_count = $expressionAdd.error_count;	
		}
	;

    expressionCmpTemp [Expression inherited_type] returns [Expression synthesized_type]:
		{BinaryOperator b;}('<'{b = BinaryOperator.lt;} | '>'{b = BinaryOperator.gt;}) expressionAdd expressionCmpTemp [$expressionAdd.synthesized_type]
		{$synthesized_type = new BinaryExpression($inherited_type,$expressionCmpTemp.synthesized_type,b);}
	    | {$synthesized_type = $inherited_type;} 
	;

    expressionAdd returns [Expression synthesized_type,int error_count]:
		expressionMult expressionAddTemp[$expressionMult.synthesized_type]
		{
			$synthesized_type = $expressionAddTemp.synthesized_type;
			$error_count = $expressionMult.error_count;
		}
	;

    expressionAddTemp [Expression inherited_type] returns [Expression synthesized_type]:
		{BinaryOperator b;}('+'{b = BinaryOperator.add;} | '-'{b = BinaryOperator.sub;}) expressionMult expressionAddTemp[$expressionMult.synthesized_type]
		{$synthesized_type = new BinaryExpression($inherited_type,$expressionAddTemp.synthesized_type,b);}
	    | {$synthesized_type = $inherited_type;} 
	;

    expressionMult returns [Expression synthesized_type,int error_count]:
		expressionUnary expressionMultTemp[$expressionUnary.synthesized_type]
		{
			$synthesized_type = $expressionMultTemp.synthesized_type;
			$error_count = $expressionUnary.error_count;
		}
	;

    expressionMultTemp [Expression inherited_type] returns [Expression synthesized_type]:
		{BinaryOperator b;}('*'{b = BinaryOperator.mult;} | '/'{b = BinaryOperator.div;}) expressionUnary expressionMultTemp[$expressionUnary.synthesized_type]
		{
			$synthesized_type = new BinaryExpression($inherited_type,$expressionMultTemp.synthesized_type,b);
		}
	    | {$synthesized_type = $inherited_type;} 
	;

    expressionUnary returns [Expression synthesized_type,int error_count]:
		{UnaryOperator u;} ('!'{u = UnaryOperator.not;} | '-'{u = UnaryOperator.minus;}) expressionUnary 
		{ 
			$synthesized_type = new UnaryExpression(u,$expressionUnary.synthesized_type);
			$error_count = 0;
		}
	    |	
		expressionMem 
		{
			$synthesized_type = $expressionMem.synthesized_type;
			$error_count = $expressionMem.error_count;
		}
	;

    expressionMem returns [Expression synthesized_type,int error_count]:
		expressionMethods expressionMemTemp[$expressionMethods.synthesized_type]
		{
			$synthesized_type = $expressionMemTemp.synthesized_type;
			$error_count = $expressionMethods.error_count;
		}
	;

    expressionMemTemp [Expression inherited_type] returns [Expression synthesized_type]:
		'[' expression ']' 
		{$synthesized_type = new ArrayCall($inherited_type,$expression.synthesized_type);}
	    | {$synthesized_type = $inherited_type;}
	;
	expressionMethods returns [Expression synthesized_type,int error_count]:
	    expressionOther expressionMethodsTemp[$expressionOther.synthesized_type]
		{
			$synthesized_type = $expressionMethodsTemp.synthesized_type;
			$error_count = $expressionOther.error_count;
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
    expressionOther returns [Expression synthesized_type,int error_count]:
		{$error_count = 0;}
		(
			CONST_NUM {$synthesized_type = new IntValue(Integer.parseInt($CONST_NUM.getText()), new IntType());}
        |	CONST_STR {$synthesized_type = new StringValue($CONST_STR.getText(),new StringType());}
        |   'new ' 'int' '[' index = CONST_NUM ']' 
		{
			$synthesized_type = new NewArray();
			((NewArray)$synthesized_type).setExpression(new IntValue(Integer.parseInt($index.text),new IntType()));
			if (Integer.parseInt($index.text) <= 0) {
        		$error_count = 1;
        		System.out.printf("Line:%d:Array length should not be zero or negative\n", $index.getLine());
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