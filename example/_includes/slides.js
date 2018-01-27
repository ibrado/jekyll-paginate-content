<script>
// Adapted from https://stackoverflow.com/questions/5597060/detecting-arrow-key-presses-in-javascript
function setup_keypress() {
  document.onkeydown = function(e) {
    switch (e.keyCode) {
      {% if paginator.has_previous %}
      case 37:
          document.location.href = "{{ paginator.previous_path }}"; 
          break;
      {% endif %}
      case 38:
          document.location.href = "{{ paginator.single_page }}#{{ paginator.section_id }}"; 
          break;
      {% if paginator.has_next %}
      case 39:
          document.location.href = "{{ paginator.next_path }}"; 
          break;
      {% endif %}
    }
  }
}

</script>
