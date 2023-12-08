import {writable} from 'svelte/store';

const initialValue: boolean = JSON.parse(localStorage['show_identities']);
export const showIdentities = writable(initialValue);
showIdentities.subscribe(value => localStorage['show_identities'] = value);
