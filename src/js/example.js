
$(document).ready(function(){
    $("button").button();
    $("#test").click( function(){
        Application.test( new Person( $("#name").val(),
                                    $("#surname").val(),
                                    parseInt($("#age").val()))); });
    $("#speed").slider({ step: .01, min: -.3, max: .3, slide:
        function(event, v) { Application.setSpeed(v.value); }});
    $("#size").slider({ step: 1, min: 20, max: 200, slide:
        function(event, v) { Application.setSize(v.value); }});
    $("#color").change( function(){ Application.setColor($(this).val()); });
    $("#quit").click( function(){ Application.quit(); });
    $("select, input, textarea").uniform();
});

function Person(firstname, lastname, age) {
    this.firstname = firstname;
    this.lastname = lastname;
    this.age = age; }

