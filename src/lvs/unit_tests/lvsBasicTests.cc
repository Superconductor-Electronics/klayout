
/*

  KLayout Layout Viewer
  Copyright (C) 2006-2019 Matthias Koefferlein

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

*/

#include "tlUnitTest.h"
#include "dbReader.h"
#include "dbTestSupport.h"
#include "lymMacro.h"

TEST(1)
{
  std::string input = tl::testsrc ();
  input += "/testdata/lvs/inv.oas";
  std::string schematic = "inv.cir";   //  relative to inv.oas
  std::string au_cir = tl::testsrc ();
  au_cir += "/testdata/lvs/inv_layout.cir";
  std::string au_lvsdb = tl::testsrc ();
  au_lvsdb += "/testdata/lvs/inv.lvsdb";

  std::string output_cir = this->tmp_file ("tmp.cir");
  std::string output_lvsdb = this->tmp_file ("tmp.lvsdb");

  lym::Macro lvs;
  lvs.set_text (tl::sprintf (
      "source('%s', 'INVERTER')\n"
      "\n"
      "deep\n"
      "\n"
      "# Reports generated\n"
      "\n"
      "# LVS report to inv.lvsdb\n"
      "report_lvs('%s')\n"
      "\n"
      "# Write extracted netlist to inv_extracted.cir\n"
      "target_netlist('%s', write_spice, 'Extracted by KLayout')\n"
      "\n"
      "# Drawing layers\n"
      "\n"
      "nwell       = input(1, 0)\n"
      "active      = input(2, 0)\n"
      "pplus       = input(3, 0)\n"
      "nplus       = input(4, 0)\n"
      "poly        = input(5, 0)\n"
      "contact     = input(6, 0)\n"
      "metal1      = input(7, 0)\n"
      "metal1_lbl  = labels(7, 1)\n"
      "via1        = input(8, 0)\n"
      "metal2      = input(9, 0)\n"
      "metal2_lbl  = labels(9, 1)\n"
      "\n"
      "# Bulk layer for terminal provisioning\n"
      "\n"
      "bulk        = polygon_layer\n"
      "\n"
      "# Computed layers\n"
      "\n"
      "active_in_nwell       = active & nwell\n"
      "pactive               = active_in_nwell & pplus\n"
      "pgate                 = pactive & poly\n"
      "psd                   = pactive - pgate\n"
      "\n"
      "active_outside_nwell  = active - nwell\n"
      "nactive               = active_outside_nwell & nplus\n"
      "ngate                 = nactive & poly\n"
      "nsd                   = nactive - ngate\n"
      "\n"
      "# Device extraction\n"
      "\n"
      "# PMOS transistor device extraction\n"
      "extract_devices(mos4('PMOS'), { 'SD' => psd, 'G' => pgate, 'W' => nwell, \n"
      "                                'tS' => psd, 'tD' => psd, 'tG' => poly, 'tW' => nwell })\n"
      "\n"
      "# NMOS transistor device extraction\n"
      "extract_devices(mos4('NMOS'), { 'SD' => nsd, 'G' => ngate, 'W' => bulk, \n"
      "                                'tS' => nsd, 'tD' => nsd, 'tG' => poly, 'tW' => bulk })\n"
      "\n"
      "# Define connectivity for netlist extraction\n"
      "\n"
      "# Inter-layer\n"
      "connect(psd,        contact)\n"
      "connect(nsd,        contact)\n"
      "connect(poly,       contact)\n"
      "connect(contact,    metal1)\n"
      "connect(metal1,     metal1_lbl)   # attaches labels\n"
      "connect(metal1,     via1)\n"
      "connect(via1,       metal2)\n"
      "connect(metal2,     metal2_lbl)   # attaches labels\n"
      "\n"
      "# Global\n"
      "connect_global(bulk,  'SUBSTRATE')\n"
      "connect_global(nwell, 'NWELL')\n"
      "\n"
      "# Compare section\n"
      "\n"
      "schematic('%s')\n"
      "\n"
      "compare\n"
    , input, output_lvsdb, output_cir, schematic)
  );
  lvs.set_interpreter (lym::Macro::DSLInterpreter);
  lvs.set_dsl_interpreter ("lvs-dsl");

  EXPECT_EQ (lvs.run (), 0);

  compare_text_files (output_cir, au_cir);
  compare_text_files (output_lvsdb, au_lvsdb);
}

#if 0
TEST(2)
{
  lym::Macro lvs;
  lvs.set_text (
    "dbu 0.001\n"
    "def compare(a, b, ex)\n"
    "  a = a.to_s\n"
    "  b = b.to_s\n"
    "  if a != b\n"
    "    raise(ex + \" (actual=#{a}, ref=#{b})\")\n"
    "  end\n"
    "end\n"
    "compare(0.1.um, 0.1, \"unexpected value when converting um\")\n"
    "compare(0.1.micron, 0.1, \"unexpected value when converting micron\")\n"
    "compare(0.1.um2, 0.1, \"unexpected value when converting um2\")\n"
    "compare(0.1.mm2, 100000.0, \"unexpected value when converting mm2\")\n"
    "compare(120.dbu, 0.12, \"unexpected value when converting dbu\")\n"
    "compare((0.1.um + 120.dbu), 0.22, \"unexpected value when adding values\")\n"
    "compare(0.1.mm, 100.0, \"unexpected value when converting mm\")\n"
    "compare(1e-6.m, 1.0, \"unexpected value when converting m\")\n"
    "compare(1.um, 1.0, \"unexpected value when converting integer um\")\n"
    "compare(1.micron, 1.0, \"unexpected value when convering integer micron\")\n"
    "compare(1.um2, 1.0, \"unexpected value when converting integer um2\")\n"
    "compare(1.mm2, 1000000.0, \"unexpected value when converting integer mm2\")\n"
    "compare((1.um + 120.dbu), 1.12, \"unexpected value when adding integer values\")\n"
    "compare(1.mm, 1000.0, \"unexpected value when converting integer mm\")\n"
    "compare(1.m, 1000000.0, \"unexpected value when converting integer m\")\n"
  );
  lvs.set_interpreter (lym::Macro::DSLInterpreter);
  lvs.set_dsl_interpreter ("lvs-dsl");

  EXPECT_EQ (lvs.run (), 0);
}
#endif

