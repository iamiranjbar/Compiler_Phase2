package ast;

import ast.node.Program;
import ast.node.declaration.ClassDeclaration;
import ast.node.declaration.MethodDeclaration;
import ast.node.declaration.VarDeclaration;
import ast.node.expression.*;
import ast.node.expression.Value.BooleanValue;
import ast.node.expression.Value.IntValue;
import ast.node.expression.Value.StringValue;
import ast.node.statement.*;

public class VisitorImpl implements Visitor {

    @Override
    public void visit(Program program) {
        //TODO: implement appropriate visit functionality
        System.out.println(program.toString());
        if (program.getMainClass() != null) {
            program.getMainClass().accept(this);   
        }
        for (int i = 0; i < program.getClasses().size(); ++i) {
        	program.getClasses().get(i).accept(this);
        }
    }

    @Override
    public void visit(ClassDeclaration classDeclaration) {
        //TODO: implement appropriate visit functionality
        System.out.println(classDeclaration.toString());
        System.out.println(classDeclaration.getName().toString());
        if (classDeclaration.getParentName() != null) {
            System.out.println(classDeclaration.getParentName().toString());
        }
        for (int i = 0; i < classDeclaration.getVarDeclarations().size(); ++i) {
        	classDeclaration.getVarDeclarations().get(i).accept(this);
        }

        for (int i = 0; i < classDeclaration.getMethodDeclarations().size(); ++i) {
        	classDeclaration.getMethodDeclarations().get(i).accept(this);
        }
    }

    @Override
    public void visit(MethodDeclaration methodDeclaration) {
        //TODO: implement appropriate visit functionality
        System.out.println(methodDeclaration.toString());
        System.out.println(methodDeclaration.getName().toString());
        for (int i = 0; i < methodDeclaration.getArgs().size(); ++i) {
        	methodDeclaration.getArgs().get(i).accept(this);
        }

        for (int i = 0; i < methodDeclaration.getLocalVars().size(); ++i) {
        	methodDeclaration.getLocalVars().get(i).accept(this);
        }

        for (int i = 0; (methodDeclaration.getBody()!=null) && (i < methodDeclaration.getBody().size()); ++i) {
        	methodDeclaration.getBody().get(i).accept(this);
        }
        if (methodDeclaration.getReturnValue() != null) {
            methodDeclaration.getReturnValue().accept(this);   
        }
    }

    @Override
    public void visit(VarDeclaration varDeclaration) {
        //TODO: implement appropriate visit functionality
        System.out.println(varDeclaration.toString());
        System.out.println(varDeclaration.getIdentifier().toString());
    }

    @Override
    public void visit(ArrayCall arrayCall) {
        //TODO: implement appropriate visit functionality
        System.out.println(arrayCall.toString());
        if (arrayCall.getInstance() != null && arrayCall.getIndex() != null) {
            arrayCall.getInstance().accept(this);
            arrayCall.getIndex().accept(this);   
        }
    }

    @Override
    public void visit(BinaryExpression binaryExpression) {
        //TODO: implement appropriate visit functionality
        System.out.println(binaryExpression.toString());
        if (binaryExpression.getLeft() != null && binaryExpression.getRight() != null) {
            binaryExpression.getLeft().accept(this);
            binaryExpression.getRight().accept(this);   
        }
    }

    @Override
    public void visit(Identifier identifier) {
        //TODO: implement appropriate visit functionality
        System.out.println(identifier.toString());
    }

    @Override
    public void visit(Length length) {
        //TODO: implement appropriate visit functionality
        System.out.println(length.toString());
        if (length.getExpression() != null) {
            length.getExpression().accept(this);   
        }
    }

    @Override
    public void visit(MethodCall methodCall) {
        //TODO: implement appropriate visit functionality
        System.out.println(methodCall.toString());
        if (methodCall.getInstance() != null) {
            methodCall.getInstance().accept(this);   
        }
        if (methodCall.getMethodName() != null) {
            methodCall.getMethodName().accept(this);   
        }
        for (int i = 0; i < methodCall.getArgs().size(); ++i) {
        	methodCall.getArgs().get(i).accept(this);
        }
    }

    @Override
    public void visit(NewArray newArray) {
        //TODO: implement appropriate visit functionality
        System.out.println(newArray.toString());
        if (newArray.getExpression() != null) {
            newArray.getExpression().accept(this);   
        }
    }

    @Override
    public void visit(NewClass newClass) {
        //TODO: implement appropriate visit functionality
        System.out.println(newClass.toString());
        if (newClass.getClassName() != null) {
            newClass.getClassName().accept(this);   
        }
    }

    @Override
    public void visit(This instance) {
        //TODO: implement appropriate visit functionality
        System.out.println(instance.toString());
    }

    @Override
    public void visit(UnaryExpression unaryExpression) {
        //TODO: implement appropriate visit functionality
        System.out.println(unaryExpression.toString());
        if (unaryExpression.getValue() != null) {
            unaryExpression.getValue().accept(this);   
        }
    }

    @Override
    public void visit(BooleanValue value) {
        //TODO: implement appropriate visit functionality
        System.out.println(value.toString());
    }

    @Override
    public void visit(IntValue value) {
        //TODO: implement appropriate visit functionality
        System.out.println(value.toString());
    }

    @Override
    public void visit(StringValue value) {
        //TODO: implement appropriate visit functionality
        System.out.println(value.toString());
    }

    @Override
    public void visit(Assign assign) {
        //TODO: implement appropriate visit functionality
        System.out.println(assign.toString());
        if (assign.getlValue() != null && assign.getrValue() != null) {
            assign.getlValue().accept(this);
            assign.getrValue().accept(this);   
        }
    }

    @Override
    public void visit(Block block) {
        //TODO: implement appropriate visit functionality
        if (block != null){
            System.out.println(block.toString());
            for (int i = 0; i < block.getBody().size(); ++i) {
                block.getBody().get(i).accept(this);
            }
        }
    }

    @Override
    public void visit(Conditional conditional) {
        //TODO: implement appropriate visit functionality
        System.out.println(conditional.toString());
        if (conditional.getExpression() != null && conditional.getConsequenceBody() != null && conditional.getAlternativeBody() != null) {
            conditional.getExpression().accept(this);
            conditional.getConsequenceBody().accept(this);
            conditional.getAlternativeBody().accept(this);   
        }
    }

    @Override
    public void visit(While loop) {
        //TODO: implement appropriate visit functionality
        System.out.println(loop.toString());
        if (loop.getCondition() != null && loop.getBody() != null) {
            loop.getCondition().accept(this);
            loop.getBody().accept(this);   
        }
    }

    @Override
    public void visit(Write write) {
        //TODO: implement appropriate visit functionality
        System.out.println(write.toString());
        if (write.getArg() != null) {
            write.getArg().accept(this);   
        }
    }
}
