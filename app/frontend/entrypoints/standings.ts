import Standings from '../standings/Standings.svelte';

document.addEventListener("turbolinks:load", function () {
    const anchor = document.getElementById('standings_anchor');
    if (anchor && anchor.childNodes.length == 0) {
        new Standings({
            target: anchor,
            props: {
                tournamentId: anchor.getAttribute('data-tournament')
            }
        });
    }
});
