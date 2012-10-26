var item_rows = [];
var default_vatrate;
var vat_registered = true;
var no_cols = 8;
var tbl;

function init_rows() {
  default_vatrate = $('#sel_vat').val();
  if (default_vatrate == undefined) {
    vat_registered = false;
    no_cols = 6;
  }

  tbl = document.getElementById('itemstable');
//  var tbl = document.getElementById('itemstable');

//  Check to see if this is an empty invoice (or only 1 item added)

  if (! /You have not yet added/i.test(tbl.rows[1].cells[0].innerHTML)) {

//  we have some rows so set up the item_rows array

    for (var i=1; i<tbl.rows.length; i++) {
      var item_row = [];
      for (var j=0; j<tbl.rows[i].cells.length; j++) {
        if (! /^<input/.test(tbl.rows[i].cells[j].innerHTML)) {		// ignore edit buttons
          item_row[j] = tbl.rows[i].cells[j].innerHTML;
        }
      }
      item_rows.push(item_row);
    }
  }
}
function display_table() {
  var net = 0;
  var vat = 0;

  var item_table = '<table width="610" border="0" cellpadding="0" cellspacing="0"  id="itemstable" class="items">\n\
                      <tr>\n\
                        <th width="350">Description</th>\n\
                        <th width="50" style="text-align:right;">Unit<br/>Price</th>\n\
                        <th width="30" style="text-align:right;">Qty</th>\n\
                        <th width="50" style="text-align:right;">Sub<br/>Total</th>\n';
  if (vat_registered) {
    item_table = item_table + '\
                        <th width="30" style="text-align:center;">VAT<br/>Rate</th>\n\
                        <th width="40" style="text-align:right;">VAT<br/>Amt</th>\n';
  }
  item_table = item_table + '\
                        <th width="60" style="text-align:right;">Total</th>\n\
                        <th style="display:none;"></th>\n\
                        <th width="70" style="text-align:center;">Edit</th>\n\
                      </tr>\n';

  if (item_rows.length < 1) {

//  No items so display empty table

    item_table = item_table + '<tr>\n\
                                 <td colspan="8" style="font-style:italic;">You have not yet added any line items.</td>\n\
                               </tr>\n\
                               <tr>\n\
                                 <td colspan="8">&nbsp;</td>\n\
                               </tr>\n';
  }
  else {
    for (var i=0; i<item_rows.length; i++) {
      item_table = item_table + '<tr>\n';
      for (var j=0; j<no_cols; j++) {
        if (j == 3) {
          net = net + item_rows[i][j] * 1;
        }
        if (j == 5 && vat_registered) {
          vat = vat + item_rows[i][j] * 1;
        }
        if (j == 0) {
          item_table = item_table + '<td>' + item_rows[i][j] + '</td>\n';
        }
        else {
          if (j == no_cols-1) {
            if (item_rows[i][j] == undefined) {
              item_table = item_table + '<td style="display:none;"></td>\n';
            }
            else {
              item_table = item_table + '<td style="display:none;">' + item_rows[i][j] + '</td>\n';
            }
          }
          else {
            item_table = item_table + '<td style="text-align:right;">' + item_rows[i][j] + '</td>\n';
          }
        }
      }
      item_table = item_table + '<td nowrap="nowrap"><img src="/icons/inv_edit.png" title="Edit" onclick="amd(' + i +');"/><img src="/icons/inv_del.png" title="Delete" onclick="dlt(' + i + ');"/>';
      if (i>0) {
        item_table = item_table + '<img src="/icons/inv_up.png" title="Move Up" onclick="up(' + i +');"/>';
      }
      if (i<item_rows.length-1) {
        item_table = item_table + '<img src="/icons/inv_down.png" title="Move Down" onclick="dn(' + i + ');"/>';
      }
      item_table = item_table + '</td>\n</tr>\n';
    }
  }
  item_table = item_table + '</table>\n';
  document.getElementById('div_html').innerHTML = item_table;
  document.getElementById('invitemcount').value = item_rows.length;
  document.getElementById('st').innerHTML = net.toFixed(2);
  if (vat_registered) {
    document.getElementById('vt').innerHTML = vat.toFixed(2);
  }
  document.getElementById('tt').innerHTML = (net + vat).toFixed(2);
  document.getElementById('desc').focus();
}
function add_row() {
  var gross = 0;
  var vat = 0;
  var vatpercent = "";
  var vatrate;

  var desc = document.getElementById('desc').value;
  var price = document.getElementById('price').value * 1;
  var qty = document.getElementById('qty').value * 1;
  if (vat_registered) {
    vatrate = document.getElementById('sel_vat').value;
  }
  var cat = document.getElementById('item_cat').value;

  if (qty == "") {
    qty = 1;
  }

  var net = price * qty;

  if (vat_registered) {
    vat = net * vatrate;
    vatpercent = (vatrate * 100) + '%';
    gross = net + vat;
    vat = vat.toFixed(2);
  }
  else {
    gross = net;
  }

  if (document.getElementById('invtype').options[document.getElementById('invtype').selectedIndex].value == 'P') {

//  Determine whether to calculate vat or use manually entered numbers

    if (document.getElementById('splitvat').value.length > 0 && document.getElementById('splittotal').value.length > 0) {
      net = document.getElementById('splittotal').value * 1;
      vat = document.getElementById('splitvat').value * 1;
      vat = vat.toFixed(2);
      document.getElementById('splittotal').value = "";
      document.getElementById('splitvat').value = "";
      $('#splits').hide();

      gross = (net * 1)+(vat * 1);
    }
  }

  price = price.toFixed(2);
  net = net.toFixed(2);
  gross = gross.toFixed(2);

  var item_row;
  if (vat_registered) {
    if (/^0.00$/i.test(price)) {
      item_row = [desc,'','','','','','',''];
    }
    else {
      item_row = [desc,price,qty,net,vatpercent,vat,gross,cat];
    }
  }
  else {
    if (/^0.00$/i.test(price)) {
      item_row = [desc,'','','','',''];
    }
    else {
      item_row = [desc,price,qty,net,gross,cat];
    }
  }
  item_rows.push(item_row);

  document.getElementById('desc').value = "";
  document.getElementById('price').value = "";
  document.getElementById('qty').value = "";
  if (vat_registered) {
    $('#sel_vat').val(default_vatrate);
  }
  document.getElementById('item_cat').value = "";

  display_table();
}
function amd(row) {
  document.getElementById('desc').value = item_rows[row][0];
  document.getElementById('price').value = item_rows[row][1];
  document.getElementById('qty').value = item_rows[row][2];
  if (vat_registered) {
    $('#sel_vat').val(item_rows[row][4]);
  }
  if (item_rows[row][7] != undefined) {
    document.getElementById('item_cat').value = item_rows[row][7];
  }

  if (document.getElementById('invtype').options[document.getElementById('invtype').selectedIndex].value == 'P') {
    document.getElementById('splittotal').value = item_rows[row][3];
    document.getElementById('splitvat').value = item_rows[row][5];
    $('#splits').show();
  }

  dlt(row);
}
function dlt(row) {
  item_rows.splice(row,1);
  display_table();
}
function check_int(obj) {
  if (obj.value.length > 0 && ! /^\d+\.?\d?\d?$/.test(obj.value)) {
    errfocus = obj.name;
    document.getElementById("dialog").innerHTML = "You must enter a numeric value to no more than 2 decimal places";
    $("#dialog").dialog("open");
  }
}
Array.prototype.move_element = function(index, delta) {

  var index2, temp_item;

  if (index < 0 || index >= this.length) {
    return false;
  }
  index2 = index + delta;

  if (index2 < 0 || index2 >= this.length || index2 == index) {
    return false;
  }
  temp_item = this[index2];
  this[index2] = this[index];
  this[index] = temp_item;

  return true;
}
function up(row) {
  item_rows.move_element(row,-1);
  display_table();
}
function dn(row) {
  item_rows.move_element(row,1);
  display_table();
}
