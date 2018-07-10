/**
 *
 * @file Variable.hpp
 *
 * Program variables (and variables coming from assertion quantifiers)
 */

#ifndef __ProgramVariable__
#define __ProgramVariable__


#include <string>
#include <ostream>
#include "Formula.hpp"
#include "Signature.hpp"
#include "Sort.hpp"
#include "Term.hpp"
#include "Type.hpp"

namespace program {
    
    // TODO: refactor QVariables to directly use logic-terms
    class Variable
    {
    public:
        const std::string name;
        const Type type;
        
        virtual bool isProgramVariable() = 0;
        virtual std::shared_ptr<const logic::Term> toTerm(std::shared_ptr<const logic::Term> i) const = 0;
        
    protected:
        Variable(const std::string& name, const Type ty) : name(name), type(ty) {}
    };
    
    class PVariable : public Variable
    {
    public:
        PVariable(const std::string& name, const Type ty);
        
        ~PVariable() {}
        
        bool isProgramVariable() override { return true; }
        
        
        void recordScalarIncrement(int n);
        
        bool isBoolean() { return type == Type::TY_BOOLEAN || type == Type::TY_BOOLEAN_ARRAY; }
        
        /** Return the vampire term representing the relatived expression of
         * this variable at iteration i. If i is an empty termlist, return
         * the final expression instead
         *
         * This version only for scalar variables.
         *
         * This function should be called only after the loop has been
         * constructed, since the arity of the symbol depends on the value
         * of 'updated'
         */
        std::shared_ptr<const logic::Term> toTerm(std::shared_ptr<const logic::Term> i) const override;

        /** Same as above for array variables */
        std::shared_ptr<const logic::Term> toTerm(std::shared_ptr<const logic::Term> i, std::shared_ptr<const logic::Term> arrayIndex) const;

        friend std::ostream& operator<<(std::ostream& ostr, const PVariable& v);
        
        std::string toString() const;
    protected:
        
        /** the symbol associated to that variable in FOL terms. If extended
         is set to true, this is the symbol for extended expressions
         (used internally), else it is the one used for output
         invariants. nullptr for variables used in quantified
         expressions */
        logic::Symbol* _symbol;
        logic::Symbol* _extendedSymbol;
        
    }; // class PVariable
    
    class QVariable : public Variable
    {
    public:
        
        QVariable(const std::string& name, const Type ty) : Variable(name, ty)
        {
            switch (ty) {
                case Type::TY_INTEGER:
                    lvariable = logic::Terms::lVariable(logic::Sorts::intSort());
                    break;
                case Type::TY_BOOLEAN:
                    lvariable = logic::Terms::lVariable(logic::Sorts::boolSort());
                    break;
                default:
                    lvariable = nullptr;
            }
        }
        
        ~QVariable() {}
        
        bool isProgramVariable() override { return false; }
        
         std::shared_ptr<const logic::Term> toTerm(std::shared_ptr<const logic::Term> i) const override { return lvariable; }
        

        std::shared_ptr<const logic::LVariable> toVar() { return lvariable; }
        
        friend std::ostream& operator<<(std::ostream& ostr, const QVariable& v);
        
        std::shared_ptr<const logic::LVariable> lvariable;
        
    }; // class QVariable
    
    std::ostream& operator<<(std::ostream& ostr, const PVariable& v);
    std::ostream& operator<<(std::ostream& ostr, const QVariable& v);
    
}

#endif // __ProgramVariable__
