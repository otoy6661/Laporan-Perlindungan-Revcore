using System.Globalization;

namespace BE10Tools.Formula;

/// <summary>
/// Small arithmetic formula evaluator (numbers, variables, + - * / ^, parentheses,
/// unary minus). Used to execute the live-data/AFR conversion formulas taken
/// from source without hard-coding every call site.
/// </summary>
public static class SimpleFormula
{
    public static double Evaluate(string expression, IReadOnlyDictionary<string, double>? variables = null)
    {
        var rpn = ToRpn(Tokenize(expression));
        var stack = new Stack<double>();
        foreach (var token in rpn)
        {
            if (token.Kind == Kind.Number) { stack.Push(token.Number); continue; }
            if (token.Kind == Kind.Variable)
            {
                if (variables == null || !variables.TryGetValue(token.Text, out var value))
                    throw new InvalidOperationException($"Unknown variable '{token.Text}'.");
                stack.Push(value);
                continue;
            }
            if (token.Text == "u-") { stack.Push(-stack.Pop()); continue; }
            double b = stack.Pop(), a = stack.Pop();
            stack.Push(token.Text switch
            {
                "+" => a + b,
                "-" => a - b,
                "*" => a * b,
                "/" => a / b,
                "^" => Math.Pow(a, b),
                _ => throw new InvalidOperationException($"Unknown operator '{token.Text}'.")
            });
        }
        if (stack.Count != 1) throw new InvalidOperationException("Malformed expression.");
        return stack.Pop();
    }

    private enum Kind { Number, Variable, Operator, LParen, RParen }
    private readonly record struct Token(Kind Kind, string Text, double Number);

    private static List<Token> Tokenize(string s)
    {
        var tokens = new List<Token>();
        int i = 0;
        while (i < s.Length)
        {
            char c = s[i];
            if (char.IsWhiteSpace(c)) { i++; continue; }
            if (char.IsDigit(c) || c == '.')
            {
                int start = i;
                while (i < s.Length && (char.IsDigit(s[i]) || s[i] == '.')) i++;
                tokens.Add(new Token(Kind.Number, s[start..i], double.Parse(s[start..i], CultureInfo.InvariantCulture)));
                continue;
            }
            if (char.IsLetter(c) || c == '_')
            {
                int start = i;
                while (i < s.Length && (char.IsLetterOrDigit(s[i]) || s[i] == '_')) i++;
                tokens.Add(new Token(Kind.Variable, s[start..i], 0));
                continue;
            }
            switch (c)
            {
                case '(': tokens.Add(new Token(Kind.LParen, "(", 0)); i++; continue;
                case ')': tokens.Add(new Token(Kind.RParen, ")", 0)); i++; continue;
                case '+': case '-': case '*': case '/': case '^':
                    tokens.Add(new Token(Kind.Operator, c.ToString(), 0)); i++; continue;
                default: throw new InvalidOperationException($"Unexpected character '{c}'.");
            }
        }
        return tokens;
    }

    private static List<Token> ToRpn(List<Token> tokens)
    {
        var output = new List<Token>();
        var ops = new Stack<Token>();
        bool expectOperand = true;
        foreach (var t in tokens)
        {
            if (t.Kind == Kind.Number || t.Kind == Kind.Variable)
            {
                output.Add(t);
                expectOperand = false;
                continue;
            }
            if (t.Kind == Kind.LParen)
            {
                ops.Push(t);
                expectOperand = true;
                continue;
            }
            if (t.Kind == Kind.RParen)
            {
                while (ops.Count > 0 && ops.Peek().Kind != Kind.LParen) output.Add(ops.Pop());
                if (ops.Count == 0) throw new InvalidOperationException("Unbalanced parentheses.");
                ops.Pop();
                expectOperand = false;
                continue;
            }
            if (t.Kind == Kind.Operator)
            {
                if (expectOperand && t.Text == "-") { ops.Push(new Token(Kind.Operator, "u-", 0)); continue; }
                while (ops.Count > 0 && ops.Peek().Kind == Kind.Operator && Prec(ops.Peek().Text) >= Prec(t.Text))
                    output.Add(ops.Pop());
                ops.Push(t);
                expectOperand = true;
            }
        }
        while (ops.Count > 0)
        {
            var op = ops.Pop();
            if (op.Kind == Kind.LParen) throw new InvalidOperationException("Unbalanced parentheses.");
            output.Add(op);
        }
        return output;
    }

    private static int Prec(string op) => op switch
    {
        "u-" => 4,
        "^" => 3,
        "*" or "/" => 2,
        "+" or "-" => 1,
        _ => 0
    };
}
