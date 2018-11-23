All: make clean 


clean: 
	rm *.interp *.java *.tokens *.class
	find . -name "*.class" -type f -delete
