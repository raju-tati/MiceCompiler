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
    makeTokens(@tokens);

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
    # implement
    return 1;
}

sub defineEmbed() {
    # implement
    return 0;
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
    sub printTest() {
        print("test program", "\n");
    }

    sub anotherFunction(arg) {
        print(arg, "\n");
    }
';

my %ast = parse($program);
use Data::Printer;
p %ast;
exit;
