output "k8s_cluster_id" {
  value = oci_containerengine_cluster.k8s_cluster.id
}

output "k8s_kubeconfig" {
  value = data.oci_containerengine_cluster_kube_config.cluster_kube_config.content
}
