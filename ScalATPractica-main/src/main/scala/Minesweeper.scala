import scala.io.Source

object Minesweeper extends App {

    val e = new ScalAT("Minesweeper")

    private val directions = List(
        (-1, -1), (-1, 0), (-1, 1), // Top row: left, center, right
        (0, -1), (0, 1),             // Middle row: left, right
        (1, -1), (1, 0), (1, 1)      // Bottom row: left, center, right
    )

    // read input file from stdin
    private val lines = Source.stdin.getLines().toArray

    // First line contains N, M, and nmines
    val Array(n, m, nmines) = lines(0).split(" ").map(_.toInt)

    // Initialize the matrix as a List of Lists
    private val matrix: List[List[String]] = lines.drop(1).toList.map(_.split(" ").toList)

    // Print the parsed values for verification
    println(s"N = $n, M = $m, nmines = $nmines")
    println("Matrix:")
    matrix.foreach(row => println(row.mkString(" ")))

    //tauler(i)(j) és cert sii a la casella (i,j) hi ha una mina
    val tauler: Array[Array[Int]] = e.newVar2DArray(n, m)

    private def addSurroundingEK(neighbours: Int, x: Int, y: Int): Unit = {
        val veinsPossibles =
            for {
                (di, dj) <- directions
                ni = x + di
                nj = y + dj
                if ni >= 0 && ni < n && nj >= 0 && nj < m
            } yield (ni, nj)

        if (neighbours == 0) {
            // a les caselles surrounding segur que no hi ha una mina
            veinsPossibles.foreach(v => e.addClause(-tauler(v._1)(v._2) :: List()))
        }
        else if (neighbours == 1) {
            //e.addEOLog(veinsPossibles.map(v => tauler(v._1)(v._2)))
            e.addEOQuad(veinsPossibles.map(v => tauler(v._1)(v._2)))
        }
        else {
            e.addEK(veinsPossibles.map(v => tauler(v._1)(v._2)), K = neighbours)
        }
        e.addClause(-tauler(x)(y) :: List()) // en la casella de la restricció segur que no hi ha una mina
    }

    matrix.zipWithIndex.foreach {
        case (arr, i) => arr.zipWithIndex.foreach {
            case (variable, j) =>
                variable match {
                    case "-" =>
                    case "X" => e.addClause(-tauler(i)(j) :: List())
                    case _ => addSurroundingEK(variable.toInt, i, j)
                }
        }
    }

    if (nmines != -1) {
        e.addEK(tauler.flatten.toList, nmines)
    }

    private def printTauler: String = {
        tauler
            .map(_.map((i: Int) => if (e.getValue(i)) "o " else "X "))
            .map(_.mkString(""))
            .mkString("\n")
    }

    val result=e.solve()
    println(result)
    if (result.satisfiable) println(printTauler)
}
