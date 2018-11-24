grammar Smoola;
	@members{
	   void print(Object obj){
	        System.out.println(obj);
	   }
	}

	@header {
		import ast.node.Program;
		import ast.node.declaration.*;
		import ast.node.expression.*;
		import ast.node.expression.Value.*;
		import ast.node.statement.*;
		import ast.Type.*;
		import ast.Type.ArrayType.*;
		import ast.Type.PrimitiveType.*;
		import ast.Type.UserDefinedType.*;
	}

	program:
		program1 {print($program1.synthesized_type.toString());}
	;
    program1 returns [Program synthesized_type]:
        {$synthesized_type = new Program();} mainClass {$synthesized_type.setMainClass($mainClass.synthesized_type);} (classDeclaration {$synthesized_type.addClass($classDeclaration.synthesized_type);})* EOF
    ;
    mainClass returns [ClassDeclaration synthesized_type]:
        // name should be checked later
        'class' name = ID '{' 'def' ID '(' ')' ':' 'int' '{'  statements 'return' expression ';' '}' '}' 
		{$synthesized_type = new ClassDeclaration(new Identifier($name.getText()), null);}
    ;
    classDeclaration returns [ClassDeclaration synthesized_type]:
        'class' name = ID ('extends' father_name = ID)? 
		{$synthesized_type = new ClassDeclaration(new Identifier($name.getText()), new Identifier((($father_name != null) ? $father_name.getText() : "")));}
		'{' (varDeclaration{$synthesized_type.addVarDeclaration($varDeclaration.synthesized_type);})* 
		(methodDeclaration{$synthesized_type.addMethodDeclaration($methodDeclaration.synthesized_type);})* '}' 
		
    ;
    varDeclaration returns [VarDeclaration synthesized_type]:
        'var' ID ':' type ';' 
		{$synthesized_type = new VarDeclaration(new Identifier($ID.getText()),$type.synthesized_type);}
    ;
    methodDeclaration returns [MethodDeclaration synthesized_type]:
        'def' name = ID {$synthesized_type = new MethodDeclaration(new Identifier($name.getText()));}
		('(' ')' | ('(' n1 = ID ':' type {$synthesized_type.addArg(new VarDeclaration(new Identifier($n1.getText()),$type.synthesized_type));}
		(',' n2 = ID ':' type {$synthesized_type.addArg(new VarDeclaration(new Identifier($n2.getText()),$type.synthesized_type));})* ')'))
		':' type {$synthesized_type.setReturnType($type.synthesized_type);} '{'  
		(varDeclaration {$synthesized_type.addLocalVar($varDeclaration.synthesized_type);})* 
		statements 
		{
			$synthesized_type.addStatement($statements.synthesized_type);
		}
		'return' expression ';' '}'
    ;
    statements returns [Block synthesized_type]:
        {$synthesized_type = new Block();} (statement {$synthesized_type.addStatement($statement.synthesized_type);})*
    ;
    statement returns [Statement synthesized_type]:
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
		}
    ;
    statementBlock returns [Block synthesized_type]:
        '{' statements{ $synthesized_type = $statements.synthesized_type; } '}'
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
    statementAssignment returns [Assign synthesized_type]:
        expression ';' 
		{$synthesized_type = new Assign(((BinaryExpression)$expression.synthesized_type).getLeft(),((BinaryExpression)$expression.synthesized_type).getRight());}
    ;

    expression returns [Expression synthesized_type]:
		expressionAssignment {$synthesized_type = $expressionAssignment.synthesized_type;}
	;

    expressionAssignment returns [Expression synthesized_type]:
		expressionOr '=' expressionAssignment 
		{$synthesized_type = new BinaryExpression($expressionOr.synthesized_type,$expressionAssignment.synthesized_type,BinaryOperator.assign);}
	    |	expressionOr {$synthesized_type = $expressionOr.synthesized_type;}
	;

    expressionOr returns [Expression synthesized_type]:
		expressionAnd expressionOrTemp[$expressionAnd.synthesized_type] 
		{$synthesized_type = $expressionOrTemp.synthesized_type;}
	;

    expressionOrTemp [Expression inherited_type] returns [Expression synthesized_type]:
		'||' expressionAnd expressionOrTemp[$expressionAnd.synthesized_type] 
		{$synthesized_type = new BinaryExpression($inherited_type,$expressionOrTemp.synthesized_type,BinaryOperator.or);}
	    | {$synthesized_type = $inherited_type;}
	;

    expressionAnd returns [Expression synthesized_type]:
		expressionEq expressionAndTemp[$expressionEq.synthesized_type]
		{$synthesized_type = $expressionAndTemp.synthesized_type;}
	;

    expressionAndTemp [Expression inherited_type] returns [Expression synthesized_type]:
		'&&' expressionEq expressionAndTemp[$expressionEq.synthesized_type]
		{$synthesized_type = new BinaryExpression($inherited_type,$expressionAndTemp.synthesized_type,BinaryOperator.and);}
	    | {$synthesized_type = $inherited_type;}
	;

    expressionEq returns [Expression synthesized_type]:
		expressionCmp expressionEqTemp[$expressionCmp.synthesized_type] 
		{$synthesized_type = $expressionEqTemp.synthesized_type;}
	;

    expressionEqTemp [Expression inherited_type] returns [Expression synthesized_type]:
		{BinaryOperator b;}('=='{b = BinaryOperator.eq;}|'<>'{b = BinaryOperator.neq;}) expressionCmp expressionEqTemp[$expressionCmp.synthesized_type]
		{$synthesized_type = new BinaryExpression($inherited_type,$expressionEqTemp.synthesized_type,b);} 
	    | {$synthesized_type = $inherited_type;} 
	;

    expressionCmp returns [Expression synthesized_type]:
		expressionAdd expressionCmpTemp[$expressionAdd.synthesized_type]
		{$synthesized_type = $expressionCmpTemp.synthesized_type;}
	;

    expressionCmpTemp [Expression inherited_type] returns [Expression synthesized_type]:
		{BinaryOperator b;}('<'{b = BinaryOperator.lt;} | '>'{b = BinaryOperator.gt;}) expressionAdd expressionCmpTemp [$expressionAdd.synthesized_type]
		{$synthesized_type = new BinaryExpression($inherited_type,$expressionCmpTemp.synthesized_type,b);}
	    | {$synthesized_type = $inherited_type;} 
	;

    expressionAdd returns [Expression synthesized_type]:
		expressionMult expressionAddTemp[$expressionMult.synthesized_type]
		{$synthesized_type = $expressionAddTemp.synthesized_type;}
	;

    expressionAddTemp [Expression inherited_type] returns [Expression synthesized_type]:
		{BinaryOperator b;}('+'{b = BinaryOperator.add;} | '-'{b = BinaryOperator.sub;}) expressionMult expressionAddTemp[$expressionMult.synthesized_type]
		{$synthesized_type = new BinaryExpression($inherited_type,$expressionAddTemp.synthesized_type,b);}
	    | {$synthesized_type = $inherited_type;} 
	;

        expressionMult returns [Expression synthesized_type]:
		expressionUnary expressionMultTemp[$expressionUnary.synthesized_type]
		{$synthesized_type = $expressionMultTemp.synthesized_type;}
	;

    expressionMultTemp [Expression inherited_type] returns [Expression synthesized_type]:
		{BinaryOperator b;}('*'{b = BinaryOperator.mult;} | '/'{b = BinaryOperator.div;}) expressionUnary expressionMultTemp[$expressionUnary.synthesized_type]
		{$synthesized_type = new BinaryExpression($inherited_type,$expressionMultTemp.synthesized_type,b);}
	    | {$synthesized_type = $inherited_type;} 
	;

    expressionUnary returns [Expression synthesized_type]:
		{UnaryOperator u;} ('!'{u = UnaryOperator.not;} | '-'{u = UnaryOperator.minus;}) expressionUnary 
		{ $synthesized_type = new UnaryExpression(u,$expressionUnary.synthesized_type);}
	    |	expressionMem {$synthesized_type = $expressionMem.synthesized_type;}
	;

    expressionMem returns [Expression synthesized_type]:
		expressionMethods expressionMemTemp[$expressionMethods.synthesized_type]
		{$synthesized_type = $expressionMemTemp.synthesized_type;}
	;

    expressionMemTemp [Expression inherited_type] returns [Expression synthesized_type]:
		'[' expression ']' 
		{$synthesized_type = new ArrayCall($inherited_type,$expression.synthesized_type);}
	    | {$synthesized_type = $inherited_type;}
	;
	expressionMethods returns [Expression synthesized_type]:
	    expressionOther expressionMethodsTemp[$expressionOther.synthesized_type]
		{$synthesized_type = $expressionMethodsTemp.synthesized_type;}
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
    expressionOther returns [Expression synthesized_type]:
		CONST_NUM {$synthesized_type = new IntValue(Integer.parseInt($CONST_NUM.getText()), new IntType());}
        |	CONST_STR {$synthesized_type = new StringValue($CONST_STR.getText(),new StringType());}
        |   'new ' 'int' '[' expression ']' 
		{
			$synthesized_type = new NewArray();
			((NewArray)$synthesized_type).setExpression($expression.synthesized_type);
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