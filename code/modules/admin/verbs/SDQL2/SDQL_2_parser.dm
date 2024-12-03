//I'm pretty sure that this is a recursive [s]descent[/s] ascent parser.
//Spec
//////////
//
//	query				:	select_query | delete_query | update_query | call_query | explain
//	explain				:	'EXPLAIN' query
//
//	select_query		:	'SELECT' select_list [('FROM' | 'IN') from_list] ['WHERE' bool_expression]
//	delete_query		:	'DELETE' select_list [('FROM' | 'IN') from_list] ['WHERE' bool_expression]
//	update_query		:	'UPDATE' select_list [('FROM' | 'IN') from_list] 'SET' assignments ['WHERE' bool_expression]
//	call_query			:	'CALL' call_function ['ON' select_list [('FROM' | 'IN') from_list] ['WHERE' bool_expression]]
//
//	select_list			:	select_item [',' select_list]
//	select_item			:	'*' | select_function | object_type
//	select_function		:	count_function
//	count_function		:	'COUNT' '(' '*' ')' | 'COUNT' '(' object_types ')'
//
//	from_list			:	from_item [',' from_list]
//	from_item			:	'world' | object_type
//
//	call_function		:	<function name> ['(' [arguments] ')']
//	arguments			:	expression [',' arguments]
//
//	object_type			:	<type path> | string
//
//	assignments			:	assignment, [',' assignments]
//	assignment			:	<variable name> '=' expression
//	variable			:	<variable name> | <variable name> '.' variable | '[' <hex number> ']' | '[' <hex number> ']' '.' variable
//
//	bool_expression		:	expression comparitor expression  [bool_operator bool_expression]
//	expression			:	( unary_expression | '(' expression ')' | value ) [binary_operator expression]
//	unary_expression	:	unary_operator ( unary_expression | value | '(' expression ')' )
//	comparitor			:	'=' | '==' | '!=' | '<>' | '<' | '<=' | '>' | '>='
//	value				:	variable | string | array | number | 'null'
//	unary_operator		:	'!' | '-' | '~'
//	binary_operator		:	comparitor | '+' | '-' | '/' | '*' | '&' | '|' | '^'
//	bool_operator		:	'AND' | '&&' | 'OR' | '||'
//
//	string				:	''' <some text> ''' | '"' <some text > '"'
//	array				:	'{' [arguments] '}'
//	number				:	<some digits>
//
//////////

/datum/sdql_parser
	var/query_type
	var/error = 0

	var/list/query
	var/list/tree

	var/list/select_functions = list("count")
	var/list/boolean_operators = list("and", "or", "&&", "||")
	var/list/unary_operators = list("!", "-", "~")
	var/list/binary_operators = list("+", "-", "/", "*", "&", "|", "^")
	var/list/comparitors = list("=", "==", "!=", "<>", "<", "<=", ">", ">=")

/datum/sdql_parser/New(query_list)
	query = query_list

/datum/sdql_parser/proc/parse_error(error_message)
	error = 1
	to_chat(usr, "<span class='danger'>SDQL2 Parsing Error: [error_message]</span>")
	return length(query) + 1

/datum/sdql_parser/proc/parse()
	tree = list()
	query(1, tree)

	if(error)
		return list()
	else
		return tree

/datum/sdql_parser/proc/token(i)
	if(i <= length(query))
		return query[i]

	else
		return null

/datum/sdql_parser/proc/tokens(i, num)
	if(i + num <= length(query))
		return query.Copy(i, i + num)

	else
		return null

/datum/sdql_parser/proc/tokenl(i)
	return lowertext(token(i))

//query:	select_query | delete_query | update_query
/datum/sdql_parser/proc/query(i, list/node)
	query_type = tokenl(i)

	switch(query_type)
		if("select")
			select_query(i, node)

		if("delete")
			delete_query(i, node)

		if("update")
			update_query(i, node)

		if("call")
			call_query(i, node)

		if("explain")
			node += "explain"
			node["explain"] = list()
			query(i + 1, node["explain"])


//	select_query:	'SELECT' select_list [('FROM' | 'IN') from_list] ['WHERE' bool_expression]
/datum/sdql_parser/proc/select_query(i, list/node)
	var/list/select = list()
	i = select_list(i + 1, select)

	node += "select"
	node["select"] = select

	var/list/from = list()
	if(tokenl(i) in list("from", "in"))
		i = from_list(i + 1, from)
	else
		from += "world"

	node += "from"
	node["from"] = from

	if(tokenl(i) == "where")
		var/list/where = list()
		i = bool_expression(i + 1, where)

		node += "where"
		node["where"] = where

	return i


//delete_query:	'DELETE' select_list [('FROM' | 'IN') from_list] ['WHERE' bool_expression]
/datum/sdql_parser/proc/delete_query(i, list/node)
	var/list/select = list()
	i = select_list(i + 1, select)

	node += "delete"
	node["delete"] = select

	var/list/from = list()
	if(tokenl(i) in list("from", "in"))
		i = from_list(i + 1, from)
	else
		from += "world"

	node += "from"
	node["from"] = from

	if(tokenl(i) == "where")
		var/list/where = list()
		i = bool_expression(i + 1, where)

		node += "where"
		node["where"] = where

	return i


//update_query:	'UPDATE' select_list [('FROM' | 'IN') from_list] 'SET' assignments ['WHERE' bool_expression]
/datum/sdql_parser/proc/update_query(i, list/node)
	var/list/select = list()
	i = select_list(i + 1, select)

	node += "update"
	node["update"] = select

	var/list/from = list()
	if(tokenl(i) in list("from", "in"))
		i = from_list(i + 1, from)
	else
		from += "world"

	node += "from"
	node["from"] = from

	if(tokenl(i) != "set")
		i = parse_error("UPDATE has misplaced SET")

	var/list/set_assignments = list()
	i = assignments(i + 1, set_assignments)

	node += "set"
	node["set"] = set_assignments

	if(tokenl(i) == "where")
		var/list/where = list()
		i = bool_expression(i + 1, where)

		node += "where"
		node["where"] = where

	return i


//call_query:	'CALL' call_function ['ON' select_list [('FROM' | 'IN') from_list] ['WHERE' bool_expression]]
/datum/sdql_parser/proc/call_query(i, list/node)
	var/list/func = list()
	i = variable(i + 1, func)

	node += "call"
	node["call"] = func

	if(tokenl(i) != "on")
		return i

	var/list/select = list()
	i = select_list(i + 1, select)

	node += "on"
	node["on"] = select

	var/list/from = list()
	if(tokenl(i) in list("from", "in"))
		i = from_list(i + 1, from)
	else
		from += "world"

	node += "from"
	node["from"] = from

	if(tokenl(i) == "where")
		var/list/where = list()
		i = bool_expression(i + 1, where)

		node += "where"
		node["where"] = where

	return i


//select_list:	select_item [',' select_list]
/datum/sdql_parser/proc/select_list(i, list/node)
	i = select_item(i, node)

	if(token(i) == ",")
		i = select_list(i + 1, node)

	return i


//from_list:	from_item [',' from_list]
/datum/sdql_parser/proc/from_list(i, list/node)
	i = from_item(i, node)

	if(token(i) == ",")
		i = from_list(i + 1, node)

	return i


//assignments:	assignment, [',' assignments]
/datum/sdql_parser/proc/assignments(i, list/node)
	i = assignment(i, node)

	if(token(i) == ",")
		i = assignments(i + 1, node)

	return i


//select_item:	'*' | select_function | object_type
/datum/sdql_parser/proc/select_item(i, list/node)
	if(token(i) == "*")
		node += "*"
		i++

	else if(tokenl(i) in select_functions)
		i = select_function(i, node)

	else
		i = object_type(i, node)

	return i


//from_item:	'world' | object_type
/datum/sdql_parser/proc/from_item(i, list/node)

	if(token(i) == "world")
		node += "world"
		i++

	else
		i = object_type(i, node)

	return i


//bool_expression:	expression [bool_operator bool_expression]
/datum/sdql_parser/proc/bool_expression(i, list/node)
	var/list/bool = list()
	i = expression(i, bool)

	node[++node.len] = bool

	if(tokenl(i) in boolean_operators)
		i = bool_operator(i, node)
		i = bool_expression(i, node)

	return i


//assignment:	<variable name> '=' expression
/datum/sdql_parser/proc/assignment(i, list/node, list/assignment_list = list())
	assignment_list += token(i)

	if(token(i + 1) == ".")
		i = assignment(i + 2, node, assignment_list)

	else if(token(i + 1) == "=")
		var/exp_list = list()
		node[assignment_list] = exp_list

		i = expression(i + 2, exp_list)

	else
		parse_error("Assignment expected, but no = found")

	return i


//variable:	<variable name> | <variable name> '.' variable
/datum/sdql_parser/proc/variable(i, list/node)
	var/list/L = list(token(i))
	node[++node.len] = L

	if(token(i) == "\[")
		L += token(i + 1)
		i += 2

		if(token(i) != "\]")
			parse_error("Missing \] at end of reference.")

	if(token(i + 1) == ".")
		L += "."
		i = variable(i + 2, L)

	else if(token(i + 1) == "(") // OH BOY PROC
		var/list/arguments = list()
		i = call_function(i, null, arguments)
		L += ":"
		L[++L.len] = arguments

	else if(token(i + 1) == "\[")	// list index
		var/list/expression = list()
		i = expression(i + 2, expression)
		if(token(i) != "]")
			parse_error("Missing ] at the end of list access.")

		L += "\["
		L[++L.len] = expression
		i++

	else
		i++

	return i


//object_type:	<type path> | string
/datum/sdql_parser/proc/object_type(i, list/node)

	if(copytext(token(i), 1, 2) == "/")
		node += token(i)

	else
		i = string(i, node)

	return i + 1


//comparitor:	'=' | '==' | '!=' | '<>' | '<' | '<=' | '>' | '>='
/datum/sdql_parser/proc/comparitor(i, list/node)

	if(token(i) in list("=", "==", "!=", "<>", "<", "<=", ">", ">="))
		node += token(i)

	else
		parse_error("Unknown comparitor [token(i)]")

	return i + 1


//bool_operator:	'AND' | '&&' | 'OR' | '||'
/datum/sdql_parser/proc/bool_operator(i, list/node)

	if(tokenl(i) in list("and", "or", "&&", "||"))
		node += token(i)

	else
		parse_error("Unknown comparitor [token(i)]")

	return i + 1


//string:	''' <some text> ''' | '"' <some text > '"'
/datum/sdql_parser/proc/string(i, list/node)

	if(copytext(token(i), 1, 2) in list("'", "\""))
		node += token(i)

	else
		parse_error("Expected string but found '[token(i)]'")

	return i + 1

 //array:	'{' expression, expression, ... '}'
/datum/sdql_parser/proc/array(i, list/node)
	// Arrays get turned into this: list("{", list(exp_1a = exp_1b, ...), ...), "{" is to mark the next node as an array.
	if(copytext(token(i), 1, 2) != "{")
		parse_error("Expected an array but found '[token(i)]'")
		return i + 1

	node += token(i) // Add the "{"
	var/list/expression_list = list()

	if(token(i + 1) != "}")
		var/list/temp_expression_list = list()

		do
			i = expression(i + 1, temp_expression_list)

			if(token(i) == ",")
				expression_list[++expression_list.len] = temp_expression_list
				temp_expression_list = list()
		while(token(i) && token(i) != "}")

		expression_list[++expression_list.len] = temp_expression_list
	else
		i++

	node[++node.len] = expression_list
	return i + 1

//call_function:	<function name> ['(' [arguments] ')']
/datum/sdql_parser/proc/call_function(i, list/node, list/arguments)
	var/list/cur_argument = list()
	if(length(tokenl(i)))
		var/procname = ""
		if(tokenl(i) == "global" && token(i + 1) == ".") // Global proc.
			i += 2
			procname = "global."
		node += procname + token(i++)
		if(token(i) != "(")
			parse_error("Expected ( but found '[token(i)]'")
		else if(token(i + 1) != ")")
			do
				i = expression(i + 1, cur_argument)
				if(token(i) == ",")
					arguments += list(cur_argument)
					cur_argument = list()
					continue
			while(token(i) && token(i) != ")")
			arguments += list(cur_argument)
		else
			i++
	else
		parse_error("Expected a function but found nothing")
	return i + 1


//select_function:	count_function
/datum/sdql_parser/proc/select_function(i, list/node)

	parse_error("Sorry, function calls aren't available yet")

	return i


//expression:	( unary_expression | '(' expression ')' | value ) [binary_operator expression]
/datum/sdql_parser/proc/expression(i, list/node)

	if(token(i) in unary_operators)
		i = unary_expression(i, node)

	else if(token(i) == "(")
		var/list/expr = list()

		i = expression(i + 1, expr)

		if(token(i) != ")")
			parse_error("Missing ) at end of expression.")

		else
			i++

		node[++node.len] = expr

	else
		i = value(i, node)

	if(token(i) in binary_operators)
		i = binary_operator(i, node)
		i = expression(i, node)

	else if(token(i) in comparitors)
		i = binary_operator(i, node)

		var/list/rhs = list()
		i = expression(i, rhs)

		node[++node.len] = rhs


	return i


//unary_expression:	unary_operator ( unary_expression | value | '(' expression ')' )
/datum/sdql_parser/proc/unary_expression(i, list/node)

	if(token(i) in unary_operators)
		var/list/unary_exp = list()

		unary_exp += token(i)
		i++

		if(token(i) in unary_operators)
			i = unary_expression(i, unary_exp)

		else if(token(i) == "(")
			var/list/expr = list()

			i = expression(i + 1, expr)

			if(token(i) != ")")
				parse_error("Missing ) at end of expression.")

			else
				i++

			unary_exp[++unary_exp.len] = expr

		else
			i = value(i, unary_exp)

		node[++node.len] = unary_exp


	else
		parse_error("Expected unary operator but found '[token(i)]'")

	return i


//binary_operator:	comparitor | '+' | '-' | '/' | '*' | '&' | '|' | '^'
/datum/sdql_parser/proc/binary_operator(i, list/node)

	if(token(i) in (binary_operators + comparitors))
		node += token(i)

	else
		parse_error("Unknown binary operator [token(i)]")

	return i + 1


//value:	variable | string | number | 'null'
/datum/sdql_parser/proc/value(i, list/node)

	if(token(i) == "null")
		node += "null"
		i++

	else if(lowertext(copytext(token(i), 1, 3)) == "0x" && isnum(hex2num(copytext(token(i), 3))))
		node += hex2num(copytext(token(i), 3))
		i++

	else if(isnum(text2num(token(i))))
		node += text2num(token(i))
		i++

	else if(copytext(token(i), 1, 2) in list("'", "\""))
		i = string(i, node)

	else if(copytext(token(i), 1, 2) == "{") // Start a list.
		i = array(i, node)

	else
		i = variable(i, node)

	return i
/*EXPLAIN SELECT * WHERE 42 = 6 * 9 OR val = - 5 == 7*/
