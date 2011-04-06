function add_row() {

  if (document.getElementById('desc').value.length < 1 || document.getElementById('price').value.length < 1) {
    document.getElementById('desc').value.length > 0 ? errfocus = "price" : errfocus = "desc";
    document.getElementById("dialog").innerHTML = "<ol>You have the following errors:<li>You must at least complete the Description and Price fields</li></ol>";
    $("#dialog").dialog("open");
    return false;
  }

  display_row();

  document.getElementById('desc').value = "";
  document.getElementById('price').value = "";
  document.getElementById('qty').value = "";
  document.getElementById('item_cat').value = "";
  document.getElementById('desc').focus();
}

function display_row() {

  tbl = document.getElementById('items');

//  Check to see if this is an empty invoice (or only 1 item added)

  var item_row = tbl.rows.length;
  if (item_row > 0 && /You have not yet added/i.test(tbl.rows[0].cells[0].innerHTML)) {
    document.getElementById('items').deleteRow(0);
    document.getElementById('items').deleteRow(0);
    item_row = 0;
  }
  var item_price = document.getElementById('price').value;
  var item_qty = 1;
  if (document.getElementById('qty').value.length > 0) {
    item_qty = document.getElementById('qty').value;
  }
  var item_total = item_price * item_qty;
  var sub_total = item_price * item_qty;

//  Create a new row element

  var tr = document.createElement("TR");

//  First set up the buttons

  var b1 = document.createElement("input");
  b1.setAttribute("type","button");
  b1.setAttribute("id","a" + item_row);
  b1.setAttribute("value","Amd");
  b1.onclick=function(){amd(this)};
  var b2 = document.createElement("input");
  b2.setAttribute("type","button");
  b2.setAttribute("id","d" + item_row);
  b2.setAttribute("value","Del");
  b2.onclick=function(){dlt(this)};

//  Now create 5 cells

  for (i=0; i<7; i++) {
    var td = document.createElement("TD");
    switch(i) {
     case 0:		//  Description
       td.appendChild(document.createTextNode(document.getElementById('desc').value));
       break;
     case 1:		//  Price
       td.className = "txtright";
       td.appendChild(document.createTextNode(parseFloat(item_price).toFixed(2)));
       break;
     case 2:		//  Quantity
       td.className = "txtright";
       td.appendChild(document.createTextNode(item_qty));
       break;
     case 3:		//  Sub Total
       td.className = "txtright";
       td.appendChild(document.createTextNode(parseFloat(item_total).toFixed(2)));
       break;
     case 4:		//  Item Total
       td.className = "txtright";
       td.appendChild(document.createTextNode(parseFloat(item_total).toFixed(2)));
       break;
     case 5:		//  Amd Del buttons
//     td.setAttribute("nowrap","nowrap");
       td.style.whiteSpace = "nowrap";
       td.appendChild(b1);
       td.appendChild(document.createTextNode(" "));
       td.appendChild(b2);
       break;
     case 6:
       td.className = "hidden";
       td.appendChild(document.createTextNode(document.getElementById('item_cat').value));
       break;
    }
    tr.appendChild(td);
  }
  tbl.appendChild(tr);

//  Finally add the values to the totals

  if (document.getElementById('st').innerHTML.length > 0) {
    var st1 = parseFloat(document.getElementById('st').innerHTML).toFixed(2);
    var st2 = parseFloat(sub_total).toFixed(2);
    var st = parseFloat(Number(st1) + Number(st2)).toFixed(2);
    document.getElementById('st').innerHTML = st;
  }
  else {
    document.getElementById('st').innerHTML = parseFloat(sub_total).toFixed(2);
  }
  if (document.getElementById('tt').innerHTML.length > 0) {
    var tt1 = parseFloat(document.getElementById('tt').innerHTML).toFixed(2); 
    var tt2 = parseFloat(item_total).toFixed(2);
    var tt = parseFloat(Number(tt1) + Number(tt2)).toFixed(2);
    document.getElementById('tt').innerHTML = tt;
  }
  else {
    document.getElementById('tt').innerHTML = parseFloat(item_total).toFixed(2);
  }
  document.getElementById("invitemcount").value = parseInt(document.getElementById("invitemcount").value) + 1;
}

function amd(obj) {

  var item_row = parseInt(obj.id.substring(1));
  var tbl = document.getElementById('items');

  document.getElementById('desc').value = tbl.rows[item_row].cells[0].innerHTML;
  document.getElementById('price').value = tbl.rows[item_row].cells[1].innerHTML;
  document.getElementById('qty').value = tbl.rows[item_row].cells[2].innerHTML;
  document.getElementById('item_cat').value = tbl.rows[item_row].cells[6].innerHTML;

  dlt(obj);
}

function dlt(obj) {
  var item_row = parseInt(obj.id.substring(1));
  document.getElementById('items').deleteRow(item_row);

  var st = 0;
  var tt = 0;

  var tbl = document.getElementById('items');
  if (tbl.rows.length == 0) {		// no Items
    document.getElementById("invitemcount").value = "0";
    no_items = true;
    var tr = document.createElement("tr");
    var td = document.createElement("td");
//    td.setAttribute("colspan","6");
    td.colSpan = 7;
    td.setAttribute("style","font-style:italic;");
    td.appendChild(document.createTextNode("You have not yet added any line items."));
    tr.appendChild(td);
    tbl.appendChild(tr);
    tr = document.createElement("tr");
    td = document.createElement("td");
//    td.setAttribute("colspan","6");
    td.colSpan = 7;
    td.appendChild(document.createTextNode(" "));
    tr.appendChild(td);
    tbl.appendChild(tr);
    document.getElementById('st').innerHTML = "0.00";
    document.getElementById('tt').innerHTML = "0.00";
    document.getElementById("invitemcount").value = "0";
  }
  else {
    for (i=0; i<tbl.rows.length; i++) {
      st = st + parseFloat(tbl.rows[i].cells[3].innerHTML);
      tt = tt + parseFloat(tbl.rows[i].cells[4].innerHTML);

      tbl.rows[i].cells[5].innerHTML = "<input value=\"Amd\" id=\"a" + i + "\" type=\"button\" onclick=\"amd(this);\"> <input value=\"Del\" id=\"d" + i + "\" type=\"button\" onclick=\"dlt(this);\"/>\n";
    }

    document.getElementById('st').innerHTML = st.toFixed(2);
    document.getElementById('tt').innerHTML = tt.toFixed(2);
    document.getElementById("invitemcount").value = parseInt(document.getElementById("invitemcount").value) - 1;
  }
}
function check_int(obj) {
  if (obj.value.length > 0 && ! /^\d+$/.test(obj.value)) {
    errfocus = obj.name;
    document.getElementById("dialog").innerHTML = "You must enter a whole number";
    $("#dialog").dialog("open");
  }
}
