#[derive(Drop)]
struct Stack<T> {
    data: Felt252Dict<Option<T>>,
    len: usize,
}

#[generate_trait]
impl StackImpl<T, +Drop<T>, +Copy<T>> of StackTrait<T> {
    fn push(ref self: Stack<T>, value: T) {
        self.data.insert(self.len.into(), StackTrait::new(value));
        self.len += 1;
    }

    fn pop(ref self: Stack<T>) -> Option<T> {
        if self.is_empty() {
            return Option::None;
        }
        self.len -= 1;
        Option::Some(self.data.get(self.len.into()).deref())
    }

    fn is_empty(self: @Stack<T>) -> bool {
        *self.len == 0
    }
}

#[derive(Drop, Clone)]
enum Term {
    // Variables can only bind to constants; no functors for the time being
    Var: usize,
    Const: felt252,
}

#[generate_trait]
impl TermImpl of TermTrait {
    fn match_to(self: @Term, other: @Term) -> bool {
        match (self, other) {
            (Term::Const(sc), Term::Const(oc)) => {
                sc == oc
            },
            _ => {
                panic!("unbound values");
                false
            }
        }
    }

    fn bind(ref self: Term, bindings: @Array::<felt252>) {
        match self {
            Term::Var(i) => {
                if let Option::Some(value) = bindings.get(i) {
                    self = Term::Const(*value.unbox());
                }
            },
            Term::Const(_) => {},
        }
    }
}

#[derive(Drop, Clone)]
struct Predicate {
    name: felt252,
    args: Array::<Term>,
}

#[generate_trait]
impl PredicateImpl of PredicateTrait {
    fn match_to(self: @Predicate, other: @Predicate) -> bool {
        let mut isMatch = true;
        if *self.name != *other.name {
            isMatch = false;
        } else {
            let mut i = 0;
            while i < self.args.len() {
                if ! self.args.at(i).match_to(other.args.at(i)) {
                    isMatch = false;
                    break;
                }
                i += 1;
            }
        }
        isMatch
    }

    fn bind(ref self: Predicate, bindings: @Array::<felt252>) {
        let mut i = 0;
        while i < self.args.len() {
            self.args.at(i).bind(bindings);
            i += 1;
        }
    }
}

#[derive(Drop, Clone)]
struct Clause {
    head: Predicate,
    body: Array::<Predicate>,
}

#[generate_trait]
impl ClauseImpl of ClauseTrait {
    // fn match_to(ref self: Clause, other: Clause) -> bool {
    //     let mut bindings = Felt252Dict::<felt252>::new();
    //     let mut isMatch = true;
    //     if !self.head.match_to(other.head, bindings) {
    //         isMatch = false;
    //     } else {
    //         let mut i = 0;
    //         while i < self.Body.len() {
    //             if !self.Body.at(i).match_to(other.Body.at(i), bindings) {
    //                 isMatch = false;
    //                 break;
    //             }
    //             i += 1;
    //         }
    //     }
    //     isMatch
    // }

    fn bind(ref self: Clause, bindings: @Array::<felt252>) {
        self.head.bind(bindings);
        let mut i = 0;
        while i < self.body.len() {
            self.body.at(i).bind(bindings);
            i += 1;
        }
    }
}

#[derive(Drop, Clone)]
struct Program {
    Clauses: Array::<Clause>,
}

#[generate_trait]
impl ProgramImpl of ProgramTrait {
    fn freshCopy(ref self: Program, index: usize) -> Clause {
        let clause = self.Clauses.at(index);
        clause.clone()
    }

    // Verify single item in the execution trace item against the program
    fn verify_item(ref self: Program, ref stack: Stack<Predicate>, clauseIndex: usize, variableBindings: @Array::<felt252>) -> bool {
        if (stack.is_empty()) {
            return false;
        } else {
            let mut clause = self.freshCopy(clauseIndex);
            clause.bind(variableBindings);
            if let Some(predicate::<Predicate>) = stack.pop() {
                if !clause.head.match_to(predicate) {
                    return false;
                }
            }
            let mut i = clause.body.len();
            while i > 0 {
                stack.push(clause.body.at(i-1));
                i -= 1;
            }
            true
        }
    }

    // Verify the execution trace against the program
    fn verify(ref self: Program, executionTrace: ExecutionTrace) -> bool {
        let mut stack = Stack::<Predicate>::new();
        // Push the query to the stack and bind its variables
        if let mut item = executionTrace.items.get(0) {
            let mut clause = self.freshCopy(item.clauseIndex);
            clause.bind(item.variableBindings);
            stack.push(clause);
        } else {
            return false;
        }
        let mut isVerified = true;
        let mut i = 1;
        while i < executionTrace.items.len() {
            if !self.verify_item(stack, item.clauseIndex, @item.variableBindings) {
                isVerified = false;
                break;
            }
            i += 1;
        }
        isVerified
    }
}

#[derive(Drop, Clone)]
struct ExecutionTraceItem {
    clauseIndex: usize,
    variableBindings: Array::<felt252>,
}

#[derive(Drop, Clone)]
struct ExecutionTrace {
    items: Array::<ExecutionTraceItem>,
}

#[generate_trait]
impl ExecutionTraceImpl of ExecutionTraceTrait {
}

fn build_program() -> Program {
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

fn build_execution_trace() -> Array::<Predicate> {
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
    let program = build_program();
    let trace = build_execution_trace();
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
