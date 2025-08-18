import { mount } from "svelte";
import BracketPage from "../pairings/BracketPage.svelte";

document.addEventListener("turbolinks:load", function () {
  const anchor = document.getElementById("bracket_anchor");
  if (anchor && anchor.childNodes.length == 0) {
    mount(BracketPage, {
      target: anchor,
      props: {
        tournamentId:
          Number(anchor.getAttribute("data-tournament") ?? "") || -1,
      },
    });
  }
});
