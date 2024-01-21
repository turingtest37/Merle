module Merle

using Genie, Genie.Renderer, Genie.Requests, Genie.Responses

export go

function go()



    Genie.config.server_host = "127.0.0.1"
    Genie.config.server_port = 8000
    Genie.config.run_as_server = true

    # @show Genie.config

    route("/sparql", method="POST") do
        params = getpayload()
        @show params
        # println("query: ",request.query)
        # println("body: ",request.body)
        # qstr = request.query["query"]
        # defgraph = request.query["default-graph-uri"]                                 
        # println("SPARQL POST $qstr $defgraph")
        @show postpayload()
        body = postpayload(:query, undef)
        @show body

        # response.headers { "Content-Type" => "application/sparql-results+xml" }
        respond(
            """
            <?xml version="1.0"?>
            <sparql xmlns="http://www.w3.org/2005/sparql-results#">
            <head>
            <variable name="val"/>
            <variable name="result"/>
            </head>
            <results>
                <result>
                    <binding name="val">
                    <literal>Bob Hacker</literal>
                    </binding>
                    <binding name="result">
                    <literal>1.223</literal>
                    </binding>
                </result>
            </results>
            </sparql>
            """, "application/sparql-results+xml")

    end

    
    route("/sparql", method="GET") do
        params = getpayload()
        @show params
        # println("query: ",request.query)
        # println("body: ",request.body)
        qstr = getpayload(:query, "")
        @show qstr
        # defgraph = getpayload(:default-graph-uri,"<default>")
        # println("SPARQL GET $qstr $defgraph")
        respond(
        """
        <?xml version="1.0"?>
        <sparql xmlns="http://www.w3.org/2005/sparql-results#">
        <head>
        <variable name="val"/>
        <variable name="result"/>
        </head>
        <results>
            <result>
                <binding name="val">
                <literal>Bob Hacker</literal>
                </binding>
                <binding name="result">
                <literal>1.223</literal>
                </binding>
            </result>
        </results>
        </sparql>
        """, "application/sparql-results+xml")
    end
    Genie.up()
    # Post("/sparql", (req,res)->(begin
    #     println("params: ",req.params)
    #     println("query: ",req.query)
    #     println("body: ",req.body)
    #     response.headers["Content-Type"] = "application/sparql-results+xml"
    #     """
    #     <?xml version="1.0"?>
    #     <sparql xmlns="http://www.w3.org/2005/sparql-results#">
    #     <head>
    #         <variable name="result"/>
    #     </head>
    #     <results>
    #     <result>
    #         <binding name="result">
    #             <literal>Bob Hacker</literal>
    #         </binding>
    #         <binding name="result">
    #         <uri>http://www.example/bob</uri>
    #         </binding>
    #     </result>
    #     </results>
    #     </sparql>
    #     """
    # end))
    
    # Get("/sparql", (req,res)->(begin
    #     println("params: ",req.params)
    #     println("query: ",req.query)
    #     println("body: ",req.body)
    #     response.headers["Content-Type"] = "application/sparql-results+xml"
    #     """
    #     <?xml version="1.0"?>
    #     <sparql xmlns="http://www.w3.org/2005/sparql-results#">
    #     <head>
    #         <variable name="result"/>
    #     </head>
    #     <results>
    #     <result>
    #     <binding name="result">
    #         <literal>Bob Hacker</literal>
    #     </binding>
    #     <binding name="result">
    #         <uri>http://www.example/bob</uri>
    #     </binding>
    #     </result>
    #     </results>
    #     </sparql>
    #     """
    # end))
    
    # Merly.start(;host="127.0.0.1",port=8000,verbose=true)

end


end # module Merle
