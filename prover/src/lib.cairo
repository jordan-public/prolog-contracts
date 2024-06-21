#[derive(Drop)]
enum Term {
    // Variables can only bind to constants; no functors for the time being
    Var: u16,
    Const: felt252,
}

#[derive(Drop)]
struct Predicate {
    Name: felt252,
    Args: Array::<Term>,
}

#[derive(Drop)]
struct Clause {
    Head: Predicate,
    Body: Array::<Predicate>,
}

#[derive(Drop)]
struct Program {
    Clauses: Array::<Clause>,
}

fn buildProgram() -> Program {
    let mut clauses = ArrayTrait::<Clause>::new();
    let mut clause = Clause {
        Head: Predicate {
            Name: 'grandparent',
            Args: array![Term::Var(0), Term::Var(1)],
        },
        Body: array![
            Predicate {
                Name: 'parent',
                Args: array![Term::Var(0), Term::Var(2)],
            },
            Predicate {
                Name: 'parent',
                Args: array![Term::Var(2), Term::Var(1)],
            },
        ],
    };
    clauses.append(clause);
    let mut clause = Clause {
        Head: Predicate {
            Name: 'parent',
            Args: array![Term::Const('adam'), Term::Const('seth')],
        },
        Body: array![],
    };
    clauses.append(clause);
    let mut clause = Clause {
        Head: Predicate {
            Name: 'parent',
            Args: array![Term::Const('seth'), Term::Const('enosh')],
        },
        Body: array![],
    };
    clauses.append(clause);
    let mut clause = Clause {
        Head: Predicate {
            Name: 'parent',
            Args: array![Term::Const('adam'), Term::Const('cain')],
        },
        Body: array![],
    };
    clauses.append(clause);
    Program { Clauses: clauses }
}

fn buildExecutionTrace() -> Array::<Predicate> {
    let mut trace = ArrayTrait::<Predicate>::new();
    let mut predicate = Predicate {
        Name: 'grandparent',
        Args: array![Term::Const('adam'), Term::Const('enosh')],
    };
    trace.append(predicate);
    let mut predicate = Predicate {
        Name: 'parent',
        Args: array![Term::Const('adam'), Term::Const('seth')],
    };
    trace.append(predicate);
    let mut predicate = Predicate {
        Name: 'parent',
        Args: array![Term::Const('seth'), Term::Const('enosh')],
    };
    trace.append(predicate);
    trace
}

fn main() -> u32 {
    // let program = buildProgram();
    // let trace = ExecutionTrace();
    // let mut result = 0;
    // for clause in program.Clauses {
    //     let mut match = true;
    //     for predicate in clause.Body {
    //         if !trace.contains(predicate) {
    //             match = false;
    //             break;
    //         }
    //     }
    //     if match {
    //         result = result + 1;
    //     }
    // }
    // result
    0
}

fn fib(mut n: u32) -> u32 {
    let mut a: u32 = 0;
    let mut b: u32 = 1;
    while n != 0 {
        n = n - 1;
        let temp = b;
        b = a + b;
        a = temp;
    };
    a
}

#[cfg(test)]
mod tests {
    use super::fib;

    #[test]
    fn it_works() {
        assert(fib(16) == 987, 'it works!');
    }
}
