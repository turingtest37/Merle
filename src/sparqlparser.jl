
using Lerche

const grammar = raw"""
//    IRIREF: "<" (/[^<>"{}|^`\\]-[\x00-\x20]/)* ">"
//    IRIREF: "<" (/[^<>"{}|^`\\]-[0x00-0x20]/)* ">"
IRIREF: "<" /[^<>"{}|^`\\]*/ ">"
PNAME_NS: PN_PREFIX? ":"
PNAME_LN: PNAME_NS PN_LOCAL
BLANK_NODE_LABEL: "_:" ( PN_CHARS_U | /[0-9]/ ) ((PN_CHARS|".")* PN_CHARS)?
VAR1: "?" VARNAME
VAR2: "\$" VARNAME
LANGTAG: "@" /[a-zA-Z]+/ ("-" /[a-zA-Z0-9]+/)*
INTEGER: /[0-9]+/
DECIMAL: /[0-9]*/ "." /[0-9]+/
DOUBLE: /[0-9]+/ "." /[0-9]*/ EXPONENT | "." /[0-9]+/ EXPONENT | /[0-9]+/ EXPONENT
INTEGER_POSITIVE: "+" INTEGER
DECIMAL_POSITIVE: "+" DECIMAL
DOUBLE_POSITIVE: "+" DOUBLE
INTEGER_NEGATIVE: "-" INTEGER
DECIMAL_NEGATIVE: "-" DECIMAL
DOUBLE_NEGATIVE: "-" DOUBLE
EXPONENT: /[eE][+-]?[0-9]+/
STRING_LITERAL1: "'" ( /[^0x270x5C0xA0xD]/ | ECHAR )* "'"
STRING_LITERAL2: "\"" ( /[^0x220x5C0xA0xD]/ | ECHAR )* "\""
STRING_LITERAL_LONG1: "'''" ( ( "'" | "''" )? ( /[^'\\]/ | ECHAR ) )* "'''"
//    STRING_LITERAL_LONG2: \"\"\" ( ( \" | \"\" )? ( /[^\"\\]/ | ECHAR ) )* \"\"\"
STRING_LITERAL_LONG2: \"\"\"   ( /[^\\\"]/ | ECHAR )* \"\"\"
ECHAR: "\" /[tbnrf"]/
NIL: "(" WS* ")"
WS: /[ \t\r\n\f]+/
//WS: /[0x200x90xD0xA]/
ANON: "[" WS* "]"
PN_CHARS_BASE: "A".."Z" | "a".."z" | /[\u00C0-\u00D6]/ | /[\u00D8-\u00F6]/ | /[\u00F8-\u02FF]/ | /[\u0370-\u037D]/ | /[\u037F-\u1FFF]/ | /[\u200C-\u200D]/ | /[\u2070-\u218F]/ | /[\u2C00-\u2FEF]/ | /[\u3001-\uD7FF]/ | /[\uF900-\uFDCF]/ | /[\uFDF0-\uFFFD]/ | /[\u10000-\uEFFFF]/
// PN_CHARS_BASE: /[A-Za-z]/
PN_CHARS_U: PN_CHARS_BASE | "_"
VARNAME: ( PN_CHARS_U | /[0-9]/ ) ( PN_CHARS_U | /[0-9]/ | /[\u00B7]/ | /[\u0300-\u036F]/ | /[\u203F-\u2040]/ )*
// VARNAME: ( PN_CHARS_U | /[0-9]/ ) ( PN_CHARS_U | /[0-9]/ | "\u00B7" )*
// PN_CHARS: PN_CHARS_U | "-" | /[0-9]/ 
PN_CHARS: PN_CHARS_U | "-" | "0".."9" | "\u00B7" | /[\u0300-\u036F]/ | /[\u203F-\u2040]/
PN_PREFIX: PN_CHARS_BASE ((PN_CHARS|".")* PN_CHARS)?
    PN_LOCAL: (PN_CHARS_U | ":" | /[0-9]/ | PLX ) ((PN_CHARS | "." | ":" | PLX)* (PN_CHARS | ":" | PLX) )?
    PLX: PERCENT | PN_LOCAL_ESC
    PERCENT: "%" HEX HEX
    HEX: /[0-9]/ | /[A-F]/ | /[a-f]/
    PN_LOCAL_ESC: "\" ( "_" | "~" | "." | "-" | "!" | "\$" | "&" | "'" | "(" | ")" | "*" | "+" | "," | ";" | "=" | "/" | "?" | "#" | "@" | "%" )
    
    ?start: query
    // ?queryunit: query
    ?query: prologue ( selectquery | constructquery | describequery | askquery ) valuesclause -> hit_query
    ?updateunit: update
    ?prologue: ( basedecl | prefixdecl )*
    ?basedecl: "BASE" IRIREF -> assign_base
    ?prefixdecl: "PREFIX" PNAME_NS IRIREF -> assign_prefix
    ?selectquery: selectclause datasetclause* whereclause solutionmodifier
    ?subselect: selectclause whereclause solutionmodifier valuesclause
    ?selectclause: "SELECT" ( "DISTINCT" | "REDUCED" )? ( ( var | ( "(" expression "AS" var ")" ) )+ | "*" ) -> select_vars
    ?constructquery: "CONSTRUCT" ( constructtemplate datasetclause* whereclause solutionmodifier | datasetclause* "WHERE" "{" triplestemplate? "}" solutionmodifier )
    ?describequery: "DESCRIBE" ( varoriri+ | "*" ) datasetclause* whereclause? solutionmodifier
    ?askquery: "ASK" datasetclause* whereclause solutionmodifier
    ?datasetclause: "FROM" ( defaultgraphclause | namedgraphclause )
    ?defaultgraphclause: sourceselector
    ?namedgraphclause: "NAMED" sourceselector
    ?sourceselector: iri
    ?whereclause: "WHERE"? groupgraphpattern
    ?solutionmodifier: groupclause? havingclause? orderclause? limitoffsetclauses?
    ?groupclause: "GROUP" "BY" groupcondition+
    ?groupcondition: builtincall | functioncall | "(" expression ( "AS" var )? ")" | var
    ?havingclause: "HAVING" havingcondition+
    ?havingcondition: constraint
    ?orderclause: "ORDER" "BY" ordercondition+
    ?ordercondition: ( ( "ASC" | "DESC" ) brackettedexpression ) | ( constraint | var )
    ?limitoffsetclauses: limitclause offsetclause? | offsetclause limitclause?
    ?limitclause: "LIMIT" INTEGER
    ?offsetclause: "OFFSET" INTEGER
    ?valuesclause: ( "VALUES" datablock )?
    ?update: prologue ( update1 ( ";" update )? )?
    ?update1: load | clear | drop | add | move | copy | create | insertdata | deletedata | deletewhere | modify
    ?load: "LOAD" "SILENT"? iri ( "INTO" graphref )?
    ?clear: "CLEAR" "SILENT"? graphrefall
    ?drop: "DROP" "SILENT"? graphrefall
    ?create: "CREATE" "SILENT"? graphref
    ?add: "ADD" "SILENT"? graphordefault "TO" graphordefault
    ?move: "MOVE" "SILENT"? graphordefault "TO" graphordefault
    ?copy: "COPY" "SILENT"? graphordefault "TO" graphordefault
    ?insertdata: "INSERT DATA" quaddata
    ?deletedata: "DELETE DATA" quaddata
    ?deletewhere: "DELETE WHERE" quadpattern
    ?modify: ( "WITH" iri )? ( deleteclause insertclause? | insertclause ) usingclause* "WHERE" groupgraphpattern
    ?deleteclause: "DELETE" quadpattern
    ?insertclause: "INSERT" quadpattern
    ?usingclause: "USING" ( iri | "NAMED" iri )
    ?graphordefault: "DEFAULT" | "GRAPH"? iri
    ?graphref: "GRAPH" iri
    ?graphrefall: graphref 
                | "DEFAULT" 
                | "NAMED" 
                | "ALL"
    ?quadpattern: "{" quads "}"
    ?quaddata: "{" quads "}"
    ?quads: triplestemplate? ( quadsnottriples "."? triplestemplate? )*
    ?quadsnottriples: "GRAPH" varoriri "{" triplestemplate? "}"
    ?triplestemplate: triplessamesubject ( "." triplestemplate? )?
    ?groupgraphpattern: "{" ( subselect | groupgraphpatternsub ) "}"
    ?groupgraphpatternsub: triplesblock? ( graphpatternnottriples "."? triplesblock? )*
    ?triplesblock: triplessamesubjectpath ( "." triplesblock? )?
    ?graphpatternnottriples: grouporuniongraphpattern 
                            | optionalgraphpattern 
                            | minusgraphpattern 
                            | graphgraphpattern 
                            | servicegraphpattern 
                            | filter 
                            | bind 
                            | inlinedata
    ?optionalgraphpattern: "OPTIONAL" groupgraphpattern
    ?graphgraphpattern: "GRAPH" varoriri groupgraphpattern
    ?servicegraphpattern: "SERVICE" "SILENT"? varoriri groupgraphpattern
    ?bind: "BIND" "(" expression "AS" var ")"
    ?inlinedata: "VALUES" datablock
    ?datablock: inlinedataonevar | inlinedatafull
    ?inlinedataonevar: var "{" datablockvalue* "}"
    ?inlinedatafull: ( NIL | "(" var* ")" ) "{" ( "(" datablockvalue* ")" | NIL )* "}"
    ?datablockvalue: iri | rdfliteral | numericliteral | booleanliteral | "UNDEF"
    ?minusgraphpattern: "MINUS" groupgraphpattern
    ?grouporuniongraphpattern: groupgraphpattern ( "UNION" groupgraphpattern )*
    ?filter: "FILTER" constraint
    ?constraint: brackettedexpression | builtincall | functioncall
    ?functioncall: iri arglist
    ?arglist: NIL | "(" "DISTINCT"? expression ( "," expression )* ")"
    ?expressionlist: NIL | "(" expression ( "," expression )* ")"
    ?constructtemplate: "{" constructtriples? "}"
    ?constructtriples: triplessamesubject ( "." constructtriples? )?
    ?triplessamesubject: varorterm propertylistnotempty | triplesnode propertylist
    ?propertylist: propertylistnotempty?
    ?propertylistnotempty: verb objectlist ( ";" ( verb objectlist )? )*
    ?verb: varoriri | "a"
    ?objectlist: object ( "," object )*
    ?object: graphnode
    ?triplessamesubjectpath: varorterm propertylistpathnotempty | triplesnodepath propertylistpath
    ?propertylistpath: propertylistpathnotempty?
    ?propertylistpathnotempty: ( verbpath | verbsimple ) objectlistpath ( ";" ( ( verbpath | verbsimple ) objectlist )? )*
    ?verbpath: path
    ?verbsimple: var
    ?objectlistpath: objectpath ( "," objectpath )*
    ?objectpath: graphnodepath
    ?path: pathalternative
    ?pathalternative: pathsequence ( "|" pathsequence )*
    ?pathsequence: patheltorinverse ( "/" patheltorinverse )*
    ?pathelt: pathprimary pathmod?
    ?patheltorinverse: pathelt | "^" pathelt
    ?pathmod: "?" | "*" | "+"
    ?pathprimary: iri | "a" | "!" pathnegatedpropertyset | "(" path ")"
    ?pathnegatedpropertyset: pathoneinpropertyset | "(" ( pathoneinpropertyset ( "|" pathoneinpropertyset )* )? ")"
    ?pathoneinpropertyset: iri | "a" | "^" ( iri | "a" )
    ?integer: INTEGER
    ?triplesnode: collection | blanknodepropertylist
    ?blanknodepropertylist: "[" propertylistnotempty "]"
    ?triplesnodepath: collectionpath | blanknodepropertylistpath
    ?blanknodepropertylistpath: "[" propertylistpathnotempty "]"
    ?collection: "(" graphnode+ ")"
    ?collectionpath: "(" graphnodepath+ ")"
    ?graphnode: varorterm | triplesnode
    ?graphnodepath: varorterm | triplesnodepath
    ?varorterm: var | graphterm
    ?varoriri: var | iri
    ?var: VAR1 | VAR2
    ?graphterm: iri | rdfliteral | numericliteral | booleanliteral | blanknode | NIL
    ?expression: conditionalorexpression
    ?conditionalorexpression: conditionalandexpression ( "||" conditionalandexpression )*
    ?conditionalandexpression: valuelogical ( "&&" valuelogical )*
    ?valuelogical: relationalexpression
    ?relationalexpression: numericexpression ( "=" numericexpression | "!=" numericexpression | "<" numericexpression | ">" numericexpression | "<=" numericexpression | ">=" numericexpression | "IN" expressionlist | "NOT" "IN" expressionlist )?
    ?numericexpression: additiveexpression
    ?additiveexpression: multiplicativeexpression ( "+" multiplicativeexpression | "-" multiplicativeexpression | ( numericliteralpositive | numericliteralnegative ) ( ( "*" unaryexpression ) | ( "/" unaryexpression ) )* )*
    ?multiplicativeexpression: unaryexpression ( "*" unaryexpression | "/" unaryexpression )*
    ?unaryexpression: "!" primaryexpression
                    | "+" primaryexpression
                    | "-" primaryexpression
                    | primaryexpression
    ?primaryexpression: brackettedexpression | builtincall | iriorfunction | rdfliteral | numericliteral | booleanliteral | var
    ?brackettedexpression: "(" expression ")"
    ?builtincall: aggregate
        | "STR" "(" expression ")"
        | "LANG" "(" expression ")"
        | "LANGMATCHES" "(" expression "," expression ")"
        | "DATATYPE" "(" expression ")"
        | "BOUND" "(" var ")"
        | "IRI" "(" expression ")"
        | "URI" "(" expression ")"
        | "BNODE" ( "(" expression ")" | NIL )
        | "RAND" NIL
        | "ABS" "(" expression ")"
        | "CEIL" "(" expression ")"
        | "FLOOR" "(" expression ")"
        | "ROUND" "(" expression ")"
        | "CONCAT" expressionlist
        | substringexpression
        | "STRLEN" "(" expression ")"
        | strreplaceexpression
        | "UCASE" "(" expression ")"
        | "LCASE" "(" expression ")"
        | "ENCODE_FOR_URI" "(" expression ")"
        | "CONTAINS" "(" expression "," expression ")"
        | "STRSTARTS" "(" expression "," expression ")"
        | "STRENDS" "(" expression "," expression ")"
        | "STRBEFORE" "(" expression "," expression ")"
        | "STRAFTER" "(" expression "," expression ")"
        | "YEAR" "(" expression ")"
        | "MONTH" "(" expression ")"
        | "DAY" "(" expression ")"
        | "HOURS" "(" expression ")"
        | "MINUTES" "(" expression ")"
        | "SECONDS" "(" expression ")"
        | "TIMEZONE" "(" expression ")"
        | "TZ" "(" expression ")"
        | "NOW" NIL
        | "UUID" NIL
        | "STRUUID" NIL
        | "MD5" "(" expression ")"
        | "SHA1" "(" expression ")"
        | "SHA256" "(" expression ")"
        | "SHA384" "(" expression ")"
        | "SHA512" "(" expression ")"
        | "COALESCE" expressionlist
        | "IF" "(" expression "," expression "," expression ")"
        | "STRLANG" "(" expression "," expression ")"
        | "STRDT" "(" expression "," expression ")"
        | "sameTerm" "(" expression "," expression ")"
        | "isIRI" "(" expression ")"
        | "isURI" "(" expression ")"
        | "isBLANK" "(" expression ")"
        | "isLITERAL" "(" expression ")"
        | "isNUMERIC" "(" expression ")"
        | regexexpression
        | existsfunc
        | notexistsfunc
    ?regexexpression: "REGEX" "(" expression "," expression ( "," expression )? ")"
    ?substringexpression: "SUBSTR" "(" expression "," expression ( "," expression )? ")"
    ?strreplaceexpression: "REPLACE" "(" expression "," expression "," expression ( "," expression )? ")"
    ?existsfunc: "EXISTS" groupgraphpattern
    ?notexistsfunc: "NOT" "EXISTS" groupgraphpattern
    ?aggregate: "COUNT" "(" "DISTINCT"? ( "*" | expression ) ")"
                | "SUM" "(" "DISTINCT"? expression ")"
                | "MIN" "(" "DISTINCT"? expression ")"
                | "MAX" "(" "DISTINCT"? expression ")"
                | "AVG" "(" "DISTINCT"? expression ")"
                | "SAMPLE" "(" "DISTINCT"? expression ")"
                | "GROUP_CONCAT" "(" "DISTINCT"? expression ( ";" "SEPARATOR" "=" string )? ")"
    ?iriorfunction: iri arglist?
    ?rdfliteral: string ( LANGTAG | ( "^^" iri ) )?
    ?numericliteral: numericliteralunsigned | numericliteralpositive | numericliteralnegative
    ?numericliteralunsigned: INTEGER | DECIMAL | DOUBLE
    ?numericliteralpositive: INTEGER_POSITIVE | DECIMAL_POSITIVE | DOUBLE_POSITIVE
    ?numericliteralnegative: INTEGER_NEGATIVE | DECIMAL_NEGATIVE | DOUBLE_NEGATIVE
    ?booleanliteral: "true" | "false"
    ?string: STRING_LITERAL1 | STRING_LITERAL2 | STRING_LITERAL_LONG1 | STRING_LITERAL_LONG2
    ?iri: IRIREF | prefixedname  -> hit_iri
    ?prefixedname: PNAME_LN | PNAME_NS
    ?blanknode: BLANK_NODE_LABEL | ANON

    // %import common.CNAME
    // %import common.ESCAPED_STRING
    // %import common.WS

    %ignore WS
"""

struct CalculateTree <: Transformer
    vars::Dict
end

CalculateTree() = CalculateTree(Dict())

@inline_rule hit_iri(s::CalculateTree, iri) = println(iri)

@inline_rule assign_base(s::CalculateTree, base) = begin
    @debug "assign_base" base
    s.vars[:base] = base
    base
end

@rule select_vars(s::CalculateTree, v) = begin
    @debug "select_vars" v
    s.vars[:variables] = v
    v;
end 

@rule hit_query(s::CalculateTree, query) = begin
    @debug "hit_query" query
    query
end

parser = Lark(grammar, parser="lalr", keep_all_tokens=true, transformer=CalculateTree())

spq = """
PREFIX arc: <https://example.com/arc#>
BASE </example.com/doug/>
SELECT ?j
WHERE {
    ?j a arc:Result-Type .
}
"""

Lerche.parse(parser, spq)



