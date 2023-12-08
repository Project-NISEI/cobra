import Rounds from '../pairings/Rounds.svelte';

const anchor = document.getElementById('rounds_anchor');
const rounds = new Rounds({
    target: anchor,
    props: {
        tournamentId: anchor.getAttribute('data-tournament')
    }
});

export default rounds;
