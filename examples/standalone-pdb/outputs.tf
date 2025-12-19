output "pdb" {
  description = "The PDB resource"
  value       = module.pdb.pdb
}

output "pdb_name" {
  description = "The name of the PDB"
  value       = module.pdb.name
}
