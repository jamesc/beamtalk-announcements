%% Copyright 2026 James Casey
%% SPDX-License-Identifier: Apache-2.0

-module(beamtalk_recording_announcer).

-moduledoc """
Backing store for `RecordingAnnouncer`, the announcements test double.

A recorder handle has the same tagged-map shape as the core `Announcer`
(`#{'$beamtalk_class', ref}`), so every inherited `Announcer` method
(`when:do:`, `subscriptions`, `unsubscribe:`, ...) works on it unchanged. It
also carries `log`: an anonymous public `ordered_set` ETS table, keyed by a
monotonic integer, holding each recorded event in arrival order.

The table belongs to the process that created the recorder and is deleted
when that process exits, so a recorder made in a test dies with the test.
Any process may record into it.
""".

-export([
    new/0,
    record/2,
    announcements/1,
    reset/1
]).

-type recorder() :: #{
    '$beamtalk_class' := 'RecordingAnnouncer',
    ref := reference(),
    log := ets:tid()
}.
-export_type([recorder/0]).

-doc "Mint a recorder handle with a fresh, empty log owned by the caller.".
-spec new() -> recorder().
new() ->
    Log = ets:new(beamtalk_recording_announcer, [ordered_set, public]),
    #{'$beamtalk_class' => 'RecordingAnnouncer', ref => make_ref(), log => Log}.

-doc "Append `Event` to the recorder's log. Never dispatches it.".
-spec record(recorder(), term()) -> nil.
record(#{log := Log}, Event) ->
    true = ets:insert(Log, {erlang:unique_integer([monotonic]), Event}),
    nil.

-doc "Every recorded event, oldest first.".
-spec announcements(recorder()) -> [term()].
announcements(#{log := Log}) ->
    [Event || {_Seq, Event} <- ets:tab2list(Log)].

-doc "Forget every recorded event.".
-spec reset(recorder()) -> nil.
reset(#{log := Log}) ->
    true = ets:delete_all_objects(Log),
    nil.
