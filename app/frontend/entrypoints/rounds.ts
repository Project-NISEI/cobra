import Rounds from '../pairings/Rounds.svelte';

document.addEventListener("turbolinks:load", function () {
    const anchor = document.getElementById('rounds_anchor');
    if (anchor && anchor.childNodes.length == 0) {
        new Rounds({
            target: anchor,
            props: {
                tournamentId: anchor.getAttribute('data-tournament')
            }
        });
    }
});
