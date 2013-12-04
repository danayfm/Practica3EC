.data
	matrixA:		.word 1,2
					.word 3,4
					.word 5,6
					.word 7,8
	rowsA:			.word 4
	columnsA:		.word 2
	
	matrixB:		.word 1,2
					.word 3,4
					.word 5,6
					.word 7,8

	rowsB:			.word 4
	columnsB:		.word 2

	
.text	
.globl main
	main:

	#LLAMADA A add_matrix
	sw $a0, 4($sp)
	sw $a1, 8($sp)
	sw $a2, 12($sp)
	sw $a3, 16($sp)
	
	la $a0, matrixA
	la $a1, matrixB
	lw $a2, rowsA
	lw $a3, columnsA
		
	jal add_matrix
	
	#LLAMAD A mult_matrix
	sw $a0, 4($sp)
	sw $a1, 8($sp)
	sw $a2, 12($sp)
	sw $a3, 16($sp)
	
	la $a0, matrixA
	la $a1, matrixB
	lw $a2, rowsA
	lw $a3, columnsA
	lw $t0 rowsB
	lw $t1 columnsB
	sw $t0, 20($sp)	
	sw $t1, 24($sp)
		
	jal mult_matrix
	
	# Recibe como primer parametro la direccion de comienzo del primer array
# Recibe como segundo parametro la direccion de comienzo del segundo array
# Recibe como tercer parametro el valor de la dimension filas del primer array
# Recibe como cuarto parametro el valor de la dimension columnas del primer array
# Recibe como quinto parametro el valor de la dimension filas del segundo array
# Recibe como sexto parametro el valor de la dimension columnas del segundo array
	
	li $v0, 10
	syscall

# RUTINA ADD 
add_matrix:
# Recibe como primer parametro la direccion de comienzo del primer array
# Recibe como segundo parametro la direccion de comienzo del segundo array
# Recibe como tercer parametro el valor de la dimension filas
# Recibe como cuarto parametro el valor de la dimension columnas
# Retorna la dirección de memoria de la matriz resultado
	
	#PRIMERO: calcular el tamaño total del array origen
	#guardar los valores de los parametros en registros temporales
	move $s0, $a0
	move $s1, $a1
	move $s3, $a2
	move $s4, $a3
	
	#total size needed = rows * columns * byte
	mul $t6, $a2, $a3
	mul $t6, $t6, 4
		
	#SEGUNDO: reservar una región del tamaño calculado
	li $v0 9
	move $a0 $t6
	syscall
	move $s2 $v0 #res
	li $s7, 0 #i=0
	for1_add:
		bge $s7, $s3, finfor1_add
		li $t8, 0 #j=0
		for2_add:
			bge $t3 $s4 finfor2_add
			
			#aux1 = get (matrixA, n_rows, n_cols, i, j);
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			move $a0, $s0
			move $a1, $s3
			move $a2, $s4
			move $a3, $s7
			sw $t8, 20($sp)
			jal get
			
			#if $v1 ==0;
			move $s5 $v0 #aux1
			bnez $v1 finfor1_add
				
			#aux2 = get (matrixB, n_rows, n_cols, i, j);
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			move $a0, $s1
			move $a1, $s3
			move $a2, $s4
			move $a3, $s7
			sw $t8, 20($sp)
			jal get
			
			#if $v1 ==0;
			move $s6 $v0 #aux2
			bnez $v1 finfor1_add #if(aux1[1]==0 && aux2[1]==0)
				
			#tmp= aux1[0] + aux2[0];				
			add $s6 $s6 $s5
			
			#set(res, n_rows, n_cols, i, j, tmp);
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			move $a0, $s2
			move $a1, $s3
			move $a2, $s4
			move $a3, $s7
			sw $t8, 20($sp)
			sw $s6, 24($sp)
			jal set
			
			add $t8 $t8 1
			b for2_add
		finfor2_add:
		add $s7 $s7 1
		b for1_add
	finfor1_add:
		#return res
		move $v0 $s2
	jr $ra


#RUTINA MULT	
mult_matrix:
# Recibe como primer parametro la direccion de comienzo del primer array
# Recibe como segundo parametro la direccion de comienzo del segundo array
# Recibe como tercer parametro el valor de la dimension filas del primer array
# Recibe como cuarto parametro el valor de la dimension columnas del primer array
# Recibe como quinto parametro el valor de la dimension filas del segundo array
# Recibe como sexto parametro el valor de la dimension columnas del segundo array
# Retorna la dirección de memoria de la matriz resultado
	## para poder multiplicar matrices A(a*b) y B (c*d), b=c, y el resultado C(a*d)
	#Suponemos que las filas y columnas de matrixA y matrixB son válidas
	#sacar los datos de los parametros y pila para su posterior uso
	move $s0, $a0 #matrixA = a0
	move $s2, $a2 #n_rowsA = a2
	move $s3, $a3 #n_colsA = a3
	move $s1, $a1 #matrixB = a1
	lw $t8, 20($sp) #n_rowsB = sacar de la pila
	lw $t9, 24($sp) #n_colsB = sacar de la pila
		
	#PRIMERO: calcular el tamaño total del array origen
	
	#total size needed = rows * columns * byte
	mul $t6, $a2, $t9
	mul $t6, $t6, 4
		
	#SEGUNDO: reservar una región del tamaño calculado
	li $v0 9
	move $a0 $t6
	syscall
	move $s6 $v0 #res
	
	li $s7,0 #i=0
	li $t3,0 #tmp=0
	for1_mult:
		bge $s7 $s0 finfor1_mult
		li $t1,0 #j=0
		for2_mult: 
			bge $t1 $t9 finfor2_mult
			li $t2,0 #k=0
			for3_mult:
				bge $t2 $s3 finfor3_mult
				#aux1= get(matrixA, n_rowsA, n_colsA, i, k);
				sub $sp $sp 20
				sw $a0, 4($sp)
				sw $a1, 8($sp)
				sw $a2, 12($sp)
				sw $a3, 16($sp)
				
				move $a0, $s0
				move $a1, $s2
				move $a2, $s3
				move $a3, $s7
				sw $t2, 20($sp)
				jal get
				
				#if $v1 ==0;
				move $s4 $v0 #aux1
				bnez $v1 finfor1
				
				#aux2= get(matrixB, n_rowsB, n_colsB, k, j);
				sw $a0, 4($sp)
				sw $a1, 8($sp)
				sw $a2, 12($sp)
				sw $a3, 16($sp)
				
				move $a0, $s1
				move $a1, $t8
				move $a2, $t9
				move $a3, $t2
				sw $t1, 20($sp)
				jal get
				
				#if $v1 ==0;
				move $s5 $v0 #aux2
				bnez $v1 finfor1
					
				#tmp=tmp + aux1[0] * aux2[0];
				mul $s4 $s4 $s5
				add $t3 $t3 $s4
				add $t2 $t2 1
				b for3_mult
			finfor3_mult:
				#set(res, n_rowsA, n_colsB, i, j, tmp);
				sw $a0, 4($sp)
				sw $a1, 8($sp)
				sw $a2, 12($sp)
				sw $a3, 16($sp)
				move $a0, $s6
				move $a1, $s2
				move $a2, $t5
				move $a3, $s7
				sw $t1, 20($sp)
				sw $t3, 24($sp)
				jal set
				li $t3, 0 #tmp=0
				#j++
				add $t1 $t1 1
				b for2_mult
		finfor2_mult:
			#i++
			add $s7 $s7 1
		b for1_mult
	finfor1_mult:
		#return res
		move $v0 $s6

	jr $ra
	
#RUTINA GET
get:
#guardamos los datos de las variables globales en registros temporales
	lw $t2, 20($sp) #column_index
	move $t3, $a3 #row_index
	move $t4, $a2 #columns
	move $t1, $a1 #rows
	move $t0, $a0 #array
	
	bge $t2, $t4 g_incorrectvalue
	bge $t3, $t1 g_incorrectvalue
	bltz $t2, g_incorrectvalue
	bltz $t3, g_incorrectvalue
	
	#v[i][j]= v + (i*columns+j)*tamaño
	mul $t3, $t3 , $t4
	add $t3, $t3, $t2
	mul $t3, $t3, 4
	add $t3, $t3, $t0
	lw $t5, ($t3)
		
	#printf(array[i][j])
	li $v0 1
	move $a0 $t5
	syscall
		# print new line
		li $a0, 10 #ascii code NL = 10
		li $v0 11
		syscall
	move $v0 $t5
	li $v1 0
	jr $ra
	
	g_incorrectvalue:
	li $v0 0 
	li $v1 -1
	
	jr $ra
	
#RUTINA SET
set:
#guardamos los datos de las variables globales en registros temporales
	lw $t5, 24($sp) #number
	lw $t2, 20($sp) #column_index
	move $t3, $a3 #row_index
	move $t4, $a2 #columns
	move $t1, $a1 #rows
	move $t0, $a0 #array
	
	bge $t2, $t4 s_incorrectvalue
	bge $t3, $t1 s_incorrectvalue
	bltz $t2, s_incorrectvalue
	bltz $t3, s_incorrectvalue
	
	#v[i][j]= v + (i*columns+j)*tamaño
	mul $t2, $t2 , $t1
	add $t2, $t2, $t3
	mul $t2, $t2, 4
	add $t2, $t2, $t0
	sw $t5, ($t2)
	li $v0, 0
	jr $ra
	
	s_incorrectvalue:
	li $v0, -1
	jr $ra
	
