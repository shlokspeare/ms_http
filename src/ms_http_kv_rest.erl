-module(ms_http_kv_rest).
-include("ms_http.hrl").

%% public
-export([
    allowed_methods/2,
    content_types_accepted/2,
    content_types_provided/2,
    delete_resource/2,
    get/2,
    init/3,
    put/2,
    resource_exists/2,
    rest_init/2,
    rest_terminate/2
]).

-define(HTTP_METHODS, [
    <<"DELETE">>,
    <<"GET">>,
    <<"PUT">>
]).

%% public
-spec allowed_methods(cowboy_req:req(), ms_req()) ->
    {[binary()], cowboy_req:req(), ms_req()}.

allowed_methods(Req, MsReq) ->
    {?HTTP_METHODS, Req, MsReq}.

-spec content_types_accepted(cowboy_req:req(), ms_req()) ->
    {[{binary(), atom()}], cowboy_req:req(), ms_req()}.

content_types_accepted(Req, MsReq) ->
    {[{<<"text/plain">>, put}], Req, MsReq}.

-spec content_types_provided(cowboy_req:req(), ms_req()) ->
    {[{binary(), atom()}], cowboy_req:req(), ms_req()}.

content_types_provided(Req, MsReq) ->
    {[{<<"text/plain">>, get}], Req, MsReq}.

-spec delete_resource(cowboy_req:req(), ms_req()) ->
    {true, cowboy_req:req(), ms_req()}.

delete_resource(Req, #ms_req {key = Key} = MsReq) ->
    ms_http_kv:delete(Key),
    {true, Req, MsReq}.

-spec get(cowboy_req:req(), ms_req()) ->
    {binary(), cowboy_req:req(), ms_req()}.

get(Req, #ms_req {value = Value} = MsReq) ->
    {Value, Req, MsReq}.

-spec init({tcp, http}, cowboy_req:req(), []) ->
    {upgrade, protocol, cowboy_rest}.

init(_Transport, _Req, _Opts) ->
    {upgrade, protocol, cowboy_rest}.

-spec put(cowboy_req:req(), ms_req()) ->
    {boolean(), cowboy_req:req(), ms_req()}.

put(Req, #ms_req {key = undefined} = MsReq) ->
    {false, Req, MsReq};
put(Req, #ms_req {key = Key} = MsReq) ->
    case cowboy_req:body(Req) of
        {ok, Value, Req2} ->
            ms_http_kv:put(Key, Value),

            {true, Req2, MsReq#ms_req {
                value = Value
            }};
        {error, _Reason} ->
            {false, Req, MsReq}
    end.

-spec resource_exists(cowboy_req:req(), ms_req()) ->
    {boolean(), cowboy_req:req(), ms_req()}.

resource_exists(Req, MsReq) ->
    case cowboy_req:binding(key, Req) of
        {undefined, Req2} ->
            {false, Req2, MsReq};
        {Key, Req2} ->
            case ms_http_kv:get(Key) of
                {ok, Value} ->
                    {true, Req2, MsReq#ms_req {
                        key = Key,
                        found = true,
                        value = Value
                    }};
                not_found ->
                    {false, Req2, MsReq#ms_req {
                        key = Key
                    }}
            end
    end.

-spec rest_init(cowboy_req:req(), []) ->
    {ok, cowboy_req:req(), ms_req()}.

rest_init(Req, []) ->
    {Method, Req2} = cowboy_req:method(Req),
    {Path, Req3} = cowboy_req:path(Req2),

    {ok, Req3, #ms_req {
        timestamp = os:timestamp(),
        method = Method,
        path = Path
    }}.

-spec rest_terminate(cowboy_req:req(), ms_req()) -> ok.

rest_terminate(_Req, _MsReq) ->
    ok.