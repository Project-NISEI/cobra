<script lang="ts">
  import { onMount } from 'svelte';
  import TournamentForm from './TournamentForm.svelte';
  
  let tournament = {
    name: '',
    date: new Date().toISOString().split('T')[0], // Today's date as default
    time_zone: Intl.DateTimeFormat().resolvedOptions().timeZone, // Browser's timezone as default
    registration_starts: '09:00',
    tournament_starts: '10:00',
    swiss_format: 'double_sided',
    stream_url: '',
    self_registration: true,
    nrdb_deck_registration: false,
    allow_self_reporting: false,
    private: false
  };
  
  let isSubmitting = false;
  let errors = null;
  let success = false;
  let createdTournamentId = null;
  
  onMount(async () => {
    try {
      // Fetch any initial data needed for the form (like available options)
      const response = await fetch('/tournaments/new', {
        headers: { 'Accept': 'application/json' }
      });
      
      if (response.ok) {
        const data = await response.json();
        // Merge any server-provided defaults with our local defaults
        if (data.tournament) {
          tournament = { ...tournament, ...data.tournament };
        }
      }
    } catch (error) {
      console.error('Failed to load form data', error);
    }
  });
  
  async function createTournament() {
    isSubmitting = true;
    errors = null;
    
    try {
      const response = await fetch('/tournaments', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
        },
        body: JSON.stringify({ tournament })
      });
      
      if (response.ok) {
        const data = await response.json();
        success = true;
        createdTournamentId = data.id;
        
        // Redirect to the new tournament after a short delay
        setTimeout(() => {
          window.location.href = `/tournaments/${createdTournamentId}/edit`;
        }, 1500);
      } else {
        const errorData = await response.json();
        errors = errorData.errors || { base: 'Failed to create tournament' };
      }
    } catch (error) {
      errors = { base: 'Network error occurred' };
    } finally {
      isSubmitting = false;
    }
  }
</script>

<div class="row">
  <div class="col-12">
    <h1>Create a tournament</h1>
    
    {#if success}
      <div class="alert alert-success">
        Tournament created successfully! Redirecting to tournament settings...
      </div>
    {:else if errors?.base}
      <div class="alert alert-danger">{errors.base}</div>
    {/if}
    
    <form on:submit|preventDefault={createTournament}>
      <TournamentForm 
        {tournament} 
        onSubmit={createTournament} 
        submitLabel="Create" 
        {isSubmitting} 
        {errors} 
      />
    </form>
  </div>
</div>