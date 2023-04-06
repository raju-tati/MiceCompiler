    use strict;
    use warnings;
    use utf8;
    use feature qw(signatures);

    no warnings "experimental::signatures";
    no warnings "experimental::smartmatch";

    use Tie::IxHash;
    my %pp = ();
    tie %pp, 'Tie::IxHash';

    ###################### Lexer Helpers

    sub makeChars($program) {
        my @chars = split("", $program);
        $pp{"chars"} = \@chars;
        $pp{"charsLength"} = $#chars;
    }

    sub programLength() {
        return $pp{"charsLength"};
    }

    sub getChar() {
        my @chars = @{$pp{"chars"}};
        my $char = shift(@chars);
        $pp{"chars"} = \@chars;
        $pp{"charsLength"} = $#chars;
        return $char;
    }

    sub nextChar() {
        my @chars = @{$pp{"chars"}};
        return $chars[0];
    }

    sub putChar($char) {
        my @chars = @{$pp{"chars"}};
        unshift(@chars, $char);
        $pp{"chars"} = \@chars;
        $pp{"charsLength"} = $#chars;
    }

    ######################### Char Groups


    sub isSpaceNewLine($char) {
        my @spaceNewLline = (" ", "\n", "\t", "\r");
        if($char ~~ @spaceNewLline) {
            return 1;
        } else {
            return 0;
        }
    }

    sub isDigit($char) {
        my @digits = ( "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" );
        foreach my $digit (@digits) {
            if ( $char eq $digit ) {
                return 1;
            }
        }
        return 0;
    }

    sub isAlpha($char) {
        my @alpha = ();

        for my $char ( 'a' ... 'z' ) {
            push @alpha, $char;
        }
        for my $char ( 'A' ... 'Z' ) {
            push @alpha, $char;
        }

        push @alpha, "_";

        if ( $char ~~ @alpha ) {
            return 1;
        }
        else {
            return 0;
        }
    }

    sub isQuote($char) {
        if ( $char eq '"' ) {
            return 1;
        }
        else {
            return 0;
        }
    }

    sub isSpecialCharachter($char) {
        my @specialCharachters = ( "{", "}", "[", "]", ",", ":", "(", ")", ";", "=", "." );

        if ( $char ~~ @specialCharachters ) {
            return 1;
        }
        else {
            return 0;
        }
    }

    sub isOperator {
        my ( $char ) = @_;
        my @operators = ( "+", "-", "|", "*", "/", ">", "<", "!", "&", "%" );

        if ( $char ~~ @operators ) {
            return 1;
        }
        else {
            return 0;
        }
    }

    ################################### Lexer

    sub lexer($program) {
        my @tokens;

        makeChars($program);

        my $counter       = 0;
        my $programLength = programLength();

        while($counter <= $programLength) {
            my $currentChar = getChar();
            $counter++;

            if(isSpaceNewLine($currentChar)) {
                next;
            }

            if ( $currentChar eq "(" && nextChar() eq "?" ) {
                my $embedBlock = "";
                getChar();
                $counter++;

                $currentChar = getChar();
                $counter++;
                while ( $currentChar ne "?" && nextChar() ne ")" ) {
                    $embedBlock .= $currentChar;
                    $currentChar = getChar();
                    $counter++;
                    while ( $currentChar ne "?" ) {
                        $embedBlock .= $currentChar;
                        $currentChar = getChar();
                        $counter++;
                    }
                }

                getChar();
                $counter++;

                my $token = { "type" => "EmbedBlock", "value" => $embedBlock };
                push( @tokens, $token );
                next;
            }

            if ( $currentChar eq "=" && nextChar() eq "=" ) {
                getChar();
                $counter++;

                my $token = { "type" => "Equals", "value" => "==" };
                push( @tokens, $token );
                next;
            }

            if ( $currentChar eq "=" && nextChar() eq ">" ) {
                getChar();
                $counter++;

                my $token = { "type" => "Each", "value" => "=>" };
                push( @tokens, $token );
                next;
            }


            if ( $currentChar eq "." && nextChar() eq "." ) {
                getChar();
                $counter++;

                my $token = { "type" => "RangeOperator", "value" => ".." };
                push( @tokens, $token );
                next;
            }

            if ( isOperator($currentChar) ) {
                if ( $currentChar eq "&" ) {
                    my $nextChar = nextChar();
                    if ( $nextChar eq "&" ) {
                        getChar();
                        $counter++;

                        my $token = { "type" => "Operator", "value" => "&&" };
                        push( @tokens, $token );
                        next;
                    }
                }
            }

            if ( isOperator($currentChar) ) {
                if ( $currentChar eq "|" ) {
                    my $nextChar = nextChar();
                    if ( $nextChar eq "|" ) {
                        getChar();
                        $counter++;

                        my $token = { "type" => "Operator", "value" => "||" };
                        push( @tokens, $token );
                        next;
                    }
                }
            }

            if ( isOperator($currentChar) ) {
                if ( $currentChar eq "!" ) {
                    my $nextChar = nextChar();
                    if ( $nextChar eq "=" ) {
                        getChar();
                        $counter++;

                        my $token = { "type" => "Operator", "value" => "!=" };
                        push( @tokens, $token );
                        next;
                    }
                }
            }

            if ( isOperator($currentChar) ) {
                if ( $currentChar eq ">" ) {
                    my $nextChar = nextChar();
                    if ( $nextChar eq "=" ) {
                        getChar();
                        $counter++;

                        my $token = { "type" => "Operator", "value" => ">=" };
                        push( @tokens, $token );
                        next;
                    }
                }
            }

            if ( isOperator($currentChar) ) {
                if ( $currentChar eq "<" ) {
                    my $nextChar = nextChar();
                    if ( $nextChar eq "=" ) {
                        getChar();
                        $counter++;

                        my $token = { "type" => "Operator", "value" => "<=" };
                        push( @tokens, $token );
                        next;
                    }
                }
            }

            if ( isOperator($currentChar) ) {
                if ( $currentChar eq "*" ) {
                    my $nextChar = nextChar();
                    if ( $nextChar eq "*" ) {
                        getChar();
                        $counter++;

                        my $token = { "type" => "Operator", "value" => "**" };
                        push( @tokens, $token );
                        next;
                    }
                }
            }

            if ( isOperator($currentChar) ) {
                my $token = { "type" => "Operator", "value" => $currentChar };
                push( @tokens, $token );
                next;
            }

            if ( isQuote($currentChar) ) {
                my $string    = "";
                my $delimiter = $currentChar;

                $currentChar = getChar();
                $counter++;

                while ( $currentChar ne $delimiter ) {
                    $string .= $currentChar;
                    $currentChar = getChar();
                    $counter++;
                }

                my $token = { "type" => "String", "value" => $string };
                push( @tokens, $token );
                next;
            }

            if ( $currentChar eq "e" && nextChar() eq "q" ) {
                getChar();
                $counter++;

                my $token = { "type" => "Operator", "value" => "eq" };
                push( @tokens, $token );
                next;
            }

            if ( $currentChar eq "n" && nextChar() eq "e" ) {
                getChar();
                $counter++;

                my $token = { "type" => "Operator", "value" => "ne" };
                push( @tokens, $token );
                next;
            }

            if ( isSpecialCharachter($currentChar) ) {
                my $token =
                { "type" => "SpecialCharachter", "value" => $currentChar };
                push( @tokens, $token );
                next;
            }

            if ( isAlpha($currentChar) ) {
                my $symbol = "";
                $symbol .= $currentChar;

                $currentChar = getChar();
                $counter++;

                while ( isAlpha($currentChar) ) {
                    $symbol .= $currentChar;
                    $currentChar = getChar();
                    $counter++;
                }

                putChar($currentChar);
                $counter = $counter - 1;

                my $token = { "type" => "Symbol", "value" => $symbol };
                push( @tokens, $token );
                next;
            }

            if ( isDigit($currentChar) ) {
                my $number = "";
                $number .= $currentChar;

                $currentChar = getChar();
                $counter++;

                while ( isDigit($currentChar) || $currentChar eq "." ) {
                    $number .= $currentChar;
                    $currentChar = getChar();
                    $counter++;
                }

                putChar($currentChar);
                $counter = $counter - 1;

                my $token = { "type" => "Number", "value" => $number };
                push( @tokens, $token );

                next;
            }

        }
        return @tokens;
    }

    ################################ ParserHelpers

    sub makeTokens(@tokens) {
        $pp{"tokens"} = \@tokens;
        $pp{"tokensLength"} = $#tokens;
    }

    sub tokensLength() {
        return $pp{"tokensLength"};
    }

    sub getToken() {
        my @tokens = @{$pp{"tokens"}};
        my $currentToken = shift(@tokens);
        $pp{"tokens"} = \@tokens;
        $pp{"tokensLength"} = $#tokens;
        return $currentToken;
    }

    sub nextToken() {
        my @tokens = @{$pp{"tokens"}};
        return $tokens[0];
    }

    sub putToken($token) {
        my @tokens = @{ $pp{"tokens"}};
        unshift(@tokens, $token);
        $pp{"tokens"} = \@tokens;
        $pp{"tokensLength"} = $#tokens;
    }

    ################################# Parser

    sub parse($program) {
        my @tokens = lexer($program);
        use Data::Printer;
        p @tokens;

        makeTokens(@tokens);
        
        #exit;
        my %hash = ();
        my $ast = lang();
        if($ast) {
            $hash{"Lang"} = $ast;
            return %hash;
        } else {
            return 0;
        }
    }

    sub lang() {
        my @functionOrEmbed = ();
        while(1) {
            my $functionOrEmbed = functionOrEmbed();
            if($functionOrEmbed) {
                push @functionOrEmbed, {"functionOrEmbed" => $functionOrEmbed};
            } else {
                return \@functionOrEmbed;
            }
        }
    }

    use Data::Printer;
    sub functionOrEmbed() {
        my $defineFunction = defineFunction();
        if($defineFunction) {
            return { "defineFunction" => $defineFunction };
        }

        my $defineEmbed = defineEmbed();
        if($defineEmbed) {
            return { "defineEmbed" => $defineEmbed };
        }

        return 0;
    }

    sub defineFunction() {
        my @functions = ();

        while(1) {
            my $function = function();
            if($function) {
                push @functions, $function;
            } 

            if($function == 0 && scalar(@functions) == 0) {
                return 0;
            }
            return \@functions;
        }
    }

    sub function() {
        my $function = {};

        my $tokenFunction = tokenFunction();
        if(! $tokenFunction) {return 0};
        $function->{"tokenFunction"} = $tokenFunction;

        my $functionName = functionName();
        if(! $functionName) { return 0; }
        $function->{"functionName"} = $functionName;

        my $lParen = lParen();
        if(! $lParen) { return 0 };
        $function->{"lParen"} = $lParen;

        my $functionParamList = functionParamList();
        if(! $functionParamList) { return 0; }
        $function->{"functionParamList"} = $functionParamList;

        my $rParen = rParen();
        if(! $rParen) { return 0 };
        $function->{"rParen"} = $rParen;

        my $codeBlock = codeBlock();
        if(! $codeBlock) { return 0; }
        $function->{"codeBlock"} = $codeBlock;

        return $function;
    }

    sub tokenFunction() {
        my $token = getToken();

        if($token->{"value"} eq "sub") {
            return "sub";
        }
        return 0;
    }

    sub functionName() {
        my $token = getToken();
        if($token) {
            return $token->{"value"};
        }
        return 0;
    }

    sub lParen() {
        my $token = getToken();
        if($token->{"value"} eq "(") {
            return "(";
        }
        return 0;
    }

    sub functionParamList() {
        my $emptyParamList = emptyParamList();
        if($emptyParamList) {
            return { "emptyParamList" => $emptyParamList };
        }

        my $functionParams = functionParams();
        if($functionParams) {
            return { "functionParams" => $functionParams };
        }

        return 0;
    }

    sub emptyParamList() {
        my $nextToken = nextToken();
        if( $nextToken->{"value"} eq ")" ) {
            return "emptyParams";
        }

        return 0;
    }

    sub functionParams() {
        my $nextToken = nextToken();
        if($nextToken->{"value"} eq ")"){
            return " ";
        }
        my @functionParams = ();
        while(1) {
            my $arg = arg();
            if($arg) {
                push @functionParams, { "arg" => $arg };
            }

            my $token = getToken();
            if($token->{value} ne ",") {
                putToken($token);
                return \@functionParams;
            }

            $arg = arg();
            if($arg) {
                push @functionParams, { "arg" => $arg };
            }
        }
    }

    sub arg() {
        my $token = getToken();
        if($token) {
            return $token->{"value"};
        } 
        return 0;
    }

    sub rParen() {
        my $token = getToken();
        if($token->{"value"} eq ")") {
            return ")";
        }
        return 0;
    }

    sub codeBlock() {
        my $codeBlock = {};

        my $lBrace = lBrace();
        if(! $lBrace) {return 0};
        $codeBlock->{"lBrace"} = $lBrace;

        my $block = blocks();
        if(! $block) { return 0; }
        $codeBlock->{"blocks"} = $block;

        # $codeBlock->{"rBrace"} = "}";
        # return $codeBlock;

        my $rBrace = rBrace();
        if(! $rBrace) {return 0};
        $codeBlock->{"rBrace"} = $rBrace;

        return $codeBlock;
        
    }

    sub blocks() {
        my @blocks = ();

        while(1) {
            my $block = block();
            if($block) {
                push @blocks, $block;
            } 

            if($block == 0 && scalar(@blocks) == 0) {
                return 0;
            }

            return \@blocks;
        }
    }

    sub block() {
        my $ifElse = ifElse();
        if($ifElse) {
            return { "ifElse" => $ifElse };
        }

        my $while1 = while1();
        if($while1) {
            return { "defineEmbed" => $while1 };
        }

        my $forEach = forEach();
        if($forEach) {
            return { "forEach" => $forEach };
        }

        my $arrayEach = arrayEach();
        if($arrayEach) {
            return { "arrayEach" => $arrayEach };
        }

        my $hashEach = hashEach();
        if($hashEach) {
            return { "hashEach" => $hashEach };
        }

        my $embBlock = embBlock();
        if($embBlock) {
            return { "embBlock" => $embBlock };
        }

        my $statement = statement();
        if($statement) {
            return { "statement" => $statement };
        }

        my $nonSyntax = nonSyntax();
        if($nonSyntax) {
            return { "nonSyntax" => $nonSyntax };
        }

        return 0;
    }

    sub nonSyntax() {
        my $token = getToken();
        print("Error at: ", $token->{"value"}, "\n");
        exit;
    }

    sub defineEmbed() {
        my $embed = {};

        my $tokenEmbed = tokenEmbed();
        if(! $tokenEmbed) {return 0}
        $embed->{"tokenEmbed"} = $tokenEmbed;

        my $tokenEmbedCode = embedCodeBlock();
        if(! $tokenEmbedCode) {return 0};
        $embed->{"tokenEmbedCode"} = $tokenEmbedCode;

        return $embed;
    }

    sub tokenEmbed() {
        my $token = getToken();
        if($token->{"value"} eq "emb") {
            return "emb";
        } else {
            putToken($token);
            return 0;
        }
    }

    sub embedCodeBlock() {
        my $token = getToken();
        if($token) {
            return $token->{"value"};
        } else {
            putToken($token);
            return 0;
        }
    }

    sub while1() {
        my $while = {};

        my $tokenWhile = tokenWhile();
        if(! $tokenWhile) {return 0}
        $while->{"tokenWhile"} = $tokenWhile;

        my $lParen = lParen();
        if(! $lParen) {return 0};
        $while->{"lParen"} = $lParen;

        my $booleanExpression = booleanExpression();
        if(! $booleanExpression) { return 0; }
        $while->{"booleanExpression"} = $booleanExpression;

        my $rParen = rParen();
        if(! $rParen) {return 0};
        $while->{"rParen"} = $rParen;

        my $codeBlock = codeBlock();
        if(! $codeBlock) {return 0};
        $while->{"codeBlock"} = $codeBlock;

        return $while;
    }

    sub forEach() {
        my $forEach = {};

        my $tokenForEach = tokenForEach();
        if(! $tokenForEach) {return 0}
        $forEach->{"tokenForEach"} = $tokenForEach;

        my $lParen = lParen();
        if(! $lParen) {return 0}
        $forEach->{"lParen"} = $lParen;

        my $forRange = forRange();
        if(! $forRange) {return 0}
        $forEach->{"forRange"} = $forRange;

        my $rParen = rParen();
        if(! $rParen) {return 0}
        $forEach->{"rParen"} = $rParen;

        my $eachSymbol = eachSymbol();
        if(! $eachSymbol) {return 0}
        $forEach->{"eachSymbol"} = $eachSymbol;

        $lParen = lParen();
        if(! $lParen) {return 0}
        $forEach->{"lParen"} = $lParen;

        my $variableName = variableName();
        if(! $variableName) {return 0}
        $forEach->{"variableName"} = $variableName;

        $rParen = rParen();
        if(! $rParen) {return 0}
        $forEach->{"rParen"} = $rParen;

        my $codeBlock = codeBlock();
        if(! $codeBlock) {return 0}
        $forEach->{"codeBlock"} = $codeBlock;
        
        return $forEach;
    }

    sub arrayEach() {
        my $arrayEach = {};

        my $tokenArrayEach = tokenArrayEach();
        if(! $tokenArrayEach) {return 0}
        $arrayEach->{"tokenArrayEach"} = $tokenArrayEach;

        my $lParen = lParen();
        if(! $lParen) {return 0}
        $arrayEach->{"lParen"} = $lParen;

        my $variableName = variableName();
        if(! $variableName) {return 0}
        $arrayEach->{"variableName"} = $variableName;

        my $rParen = rParen();
        if(! $rParen) {return 0}
        $arrayEach->{"rParen"} = $rParen;

        my $eachSymbol = eachSymbol();
        if(! $eachSymbol) {return 0}
        $arrayEach->{"eachSymbol"} = $eachSymbol;

        $lParen = lParen();
        if(! $lParen) {return 0}
        $arrayEach->{"lParen"} = $lParen;

        my $arrayEachVariableName = arrayEachVariableName();
        if(! $arrayEachVariableName) {return 0};
        $arrayEach->{"arrayEachVariableName"} = $arrayEachVariableName;

        my $comma = comma();
        if(! $comma) {return 0}
        $arrayEach->{"comma"} = $comma;

        my $arrayEachNumber = arrayEachNumber();
        if(! $arrayEachNumber) {return 0};
        $arrayEach->{"arrayEachNumber"} = $arrayEachNumber;

        $rParen = rParen();
        if(! $rParen) {return 0}
        $arrayEach->{"rParen"} = $rParen;

        my $codeBlock = codeBlock();
        if(! $codeBlock) {return 0}
        $arrayEach->{"codeBlock"} = $codeBlock;

        return $arrayEach;
    }

    sub arrayEachVariableName() {
        my $variableName = variableName();
        if($variableName) {
            return {"variableName" => $variableName};
        }

        return 0;
    }

    sub arrayEachNumber() {
        my $variableName = variableName();
        if($variableName) {
            return {"variableName" => $variableName};
        }

        return 0;
    }

    sub hashEach() {
        my $hashEach = {};

        my $tokenHashEach = tokenHashEach();
        if(! $tokenHashEach) {return 0}
        $hashEach->{"tokenHashEach"} = $tokenHashEach;

        my $lParen = lParen();
        if(! $lParen) {return 0}
        $hashEach->{"lParen"} = $lParen;

        my $variableName = variableName();
        if(! $variableName) {return 0}
        $hashEach->{"variableName"} = $variableName;

        my $rParen = rParen();
        if(! $rParen) {return 0}
        $hashEach->{"rParen"} = $rParen;

        my $eachSymbol = eachSymbol();
        if(! $eachSymbol) {return 0}
        $hashEach->{"eachSymbol"} = $eachSymbol;

        $lParen = lParen();
        if(! $lParen) {return 0}
        $hashEach->{"lParen"} = $lParen;

        my $HashEachKey = HashEachKey();
        if(! $HashEachKey) {return 0};
        $hashEach->{"HashEachKey"} = $HashEachKey;

        my $comma = comma();
        if(! $comma) {return 0}
        $hashEach->{"comma"} = $comma;

        my $HashEachValue = HashEachValue();
        if(! $HashEachValue) {return 0};
        $hashEach->{"HashEachValue"} = $HashEachValue;

        $rParen = rParen();
        if(! $rParen) {return 0}
        $hashEach->{"rParen"} = $rParen;

        my $codeBlock = codeBlock();
        if(! $codeBlock) {return 0}
        $hashEach->{"codeBlock"} = $codeBlock;

        return $hashEach;
    }

    sub hashEachKey() {
        my $variableName = variableName();
        if($variableName) {
            return {"variableName" => $variableName};
        }

        return 0;
    }

    sub hashEachValue() {
        my $variableName = variableName();
        if($variableName) {
            return {"variableName" => $variableName};
        }

        return 0;
    }

    sub forRange() {
        my $forRange = {};

        my $lowerRange = lowerRange();
        if(! $lowerRange) {return 0}
        $forRange->{"lowerRange"} = $lowerRange;

        my $rangeOperator = rangeOperator();
        if(! $rangeOperator) {return 0}
        $forRange->{"rangeOperator"} = $rangeOperator;

        my $upperRange = upperRange();
        if(! $upperRange) {return 0}
        $forRange->{"upperRange"} = $upperRange;

        return $forRange;
    }

    sub lowerRange() {
        my $string = string();
        if($string) {
            return { "string" => $string };
        }

        my $number = number();
        if($number) {
            return { "number" => $number };
        }

        my $variableName = variableName();
        if($variableName) {
            return { "variableName" => $variableName };
        }

        my $arrayElement = arrayElement();
        if($arrayElement) {
            return { "arrayElement" => $arrayElement };
        }

        my $hashElement = hashElement();
        if($hashElement) {
            return { "hashElement" => $hashElement };
        }

        my $functionReturn = functionReturn();
        if($functionReturn) {
            return { "functionReturn" => $functionReturn };
        }

        return 0;
    }


    sub upperRange() {
        my $string = string();
        if($string) {
            return { "string" => $string };
        }

        my $number = number();
        if($number) {
            return { "number" => $number };
        }

        my $variableName = variableName();
        if($variableName) {
            return { "variableName" => $variableName };
        }

        my $arrayElement = arrayElement();
        if($arrayElement) {
            return { "arrayElement" => $arrayElement };
        }

        my $hashElement = hashElement();
        if($hashElement) {
            return { "hashElement" => $hashElement };
        }

        my $functionReturn = functionReturn();
        if($functionReturn) {
            return { "functionReturn" => $functionReturn };
        }
        
        return 0;
    }

    sub ifElse() {
        my $ifElse = {};

        my $if = If();
        if(! $if) {return 0}
        $ifElse->{"if"} = $if;

        my $elseIf = elseIf();
        $ifElse->{"elseIf"} = $elseIf;

        my $else = Else();
        $ifElse->{"else"} = $else;

        return $ifElse;
    }

    sub If() {
        my $if = {};

        my $tokenIf = tokenIf();
        if(! $tokenIf) {return 0}
        $if->{"tokenIf"} = $tokenIf;

        my $lParen = lParen();
        if(! $lParen) {return 0}
        $if->{"lParen"} = $lParen;

        my $boolExpression = boolExpression();
        if(! $boolExpression) {return 0}
        $if->{"boolExpression"} = $boolExpression;

        my $rParen = rParen();
        if(! $rParen) {return 0}
        $if->{"rParen"} = $rParen;    

        my $codeBlock = codeBlock();
        if(! $codeBlock) {return 0}
        $if->{"codeBlock"} = $codeBlock;

        return $if;
    }

    sub boolExpression() {
        my @boolExpression = ();
        while(1) {
            my $booleanExpression = booleanExpression();
            if($booleanExpression) {
                push @boolExpression, $booleanExpression;
            }

            my $token = getToken();
            if($token->{"type"} ne "Operator") {
                putToken($token);
                return \@boolExpression;
            } else {
                push @boolExpression, $token->{"value"};
            }

            $booleanExpression = booleanExpression();
            if($booleanExpression) {
                push @boolExpression, $booleanExpression;
            }
        }
    }

    sub booleanExpression() {
        my $booleanExpression = {};

        my $boolOperands = boolOperands();
        if(! $boolOperands) {return 0}
        $booleanExpression->{"boolOperands"} = $boolOperands;

        my $boolOperatorExpression = boolOperatorExpression();
        $booleanExpression->{"boolOperatorExpression"} = $boolOperatorExpression;

        return $booleanExpression;
    }

    sub boolOperatorExpression() {
        my $boolOperatorExpression = {};

        my $boolOperator = boolOperator();
        if(! $boolOperator) { return 0}
        $boolOperatorExpression->{"boolOperator"} = $boolOperator;

        my $boolOperands = boolOperands();
        if(! $boolOperands) { return 0}
        $boolOperatorExpression->{"boolOperands"} = $boolOperands;

        return $boolOperatorExpression;
    }

    sub boolOperands() {
        my $realNumber = realNumber();
        if($realNumber) {
            return {"realNumber" => $realNumber};
        }

        my $string = string();
        if($string) {
            return { "string" => $string };
        }
            
        my $scalarVariable = scalarVariable();
        if($scalarVariable) {
            return { "scalarVariable" => $scalarVariable };
        }

        my $arrayElement = arrayElement();
        if($arrayElement) {
            return { "arrayElement" => $arrayElement };
        }

        my $hashElement = hashElement();
        if($hashElement) {
            return { "hashElement" => $hashElement };
        }

        my $functionReturn = functionReturn();
        if($functionReturn) {
            return { "functionReturn" => $functionReturn };
        }

        my $embedBlock = embedBlock();
        if($embedBlock) {
            return {"embedBlock" => $embedBlock};
        }

        return 0;
    }

    sub boolOperator {
        my $greaterThan = greaterThan();
        if($greaterThan) {
            return {"greaterThan" => $greaterThan};
        }

        my $lessThan = lessThan();
        if($lessThan) {
            return {"lessThan" => $lessThan};
        }

        my $equals = equals();
        if($equals) {
            return {"equals" => $equals};
        }

        my $greaterThanequals = greaterThanequals();
        if($greaterThanequals) {
            return {"equals" => $greaterThanequals};
        }

        my $percent = percent();
        if($percent) {
            return {"percent" => $percent};
        }

        my $lessThanEquals = lessThanEquals();
        if($lessThanEquals) {
            return {"lessThanEquals" => $lessThanEquals};
        }

        my $stringEquals = stringEquals();
        if($stringEquals) {
            return {"stringEquals" => $stringEquals};
        }

        my $stringNotEquals = stringNotEquals();
        if($stringNotEquals) {
            return {"stringNotEquals" => $stringNotEquals};
        }

        my $notEquals = notEquals();
        if($notEquals) {
            return {"notEquals" => $notEquals};
        }

        my $logicalAnd = logicalAnd();
        if($logicalAnd) {
            return {"logicalAnd" => $logicalAnd};
        }

        my $logicalOr = logicalOr();
        if($logicalOr) {
            return {"logicalOr" => $logicalOr};
        }

        my $embedBlock = embedBlock();
        if($embedBlock) {
            return {"embedBlock" => $embedBlock};
        }

        return 0;
    }


    sub elsif() {
        return 1;
    }


    sub lBrace() {
        my $token = getToken();
        if($token->{"value"} eq "{") {
            return "{";
        } else {
            putToken($token);
            return 0;
        }
    }

    sub rBrace() {
        my $token = getToken();
        print $token;
        if($token->{"value"} eq "}") {
            return "}";
        } else {
            putToken($token);
            return 0;
        }
    }

    #################################

    my $program = '
        sub function(arg) {
            print(arg, "\n");
        }
    ';



    my %ast = parse($program);
    use Data::Printer;
    #p $pp{"tokens"};
    #use Data::Printer;
    p %ast;
    exit;
