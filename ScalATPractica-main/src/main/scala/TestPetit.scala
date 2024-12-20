object TestPetit extends App {

    val e = new ScalAT("TestPetit")

    val variables = e.newVarArray(6).toList // a, b, c, d, e, f

    e.addEOLog(variables)
    e.addClause(-variables.head :: List())
    val result=e.solve()
    println(result)
    if (result.satisfiable) println(variables.map{ v => (v, e.getValue(v))})
}