---
sidebar_label: "Enable Local Harbor Image Registry"
title: "Enable Local Harbor Image Registry"
description: "Guide to enabling a local harbor registry on an Edge deployment."
hide_table_of_contents: false
sidebar_position: 60
tags: ["edge"]
---

Palette Edge allows you to provision a local Harbor image registry as part of your Edge deployment. When your Edge
cluster is created for the first time, all images from add-on packs downloaded from external registries are stored
locally in the Harbor registry. Subsequent image pulls from the cluster are made to the local Harbor registry. This
allows your Edge cluster to reboot containers or add new nodes without being connected to the external network.

If you specified the installation mode of the Edge Installer to be `airgap`, any images that were included in the Edge
Installer ISO will also be loaded into the Harbor registry. For more information about building content bundles, refer
to [Build Content Bundle](../../edgeforge-workflow/palette-canvos/build-content-bundle.md) and
[Build Edge Artifacts with Content Bundles](../../edgeforge-workflow/palette-canvos/palette-canvos.md).

<!-- prettier-ignore-start -->
If you enable the local Harbor registry on a cluster, the Palette agent will pull all images requested by the cluster
from the Harbor registry. If your cluster uses any image that is not included in your cluster profile, you will need to
instruct the Palette agent to not pull that image from the Harbor registry by disabling this behavior for certain
namespaces. You can do this by giving a namespace the label `stylus.io/imageswap=disable`. For more information, refer
to <VersionedLink text="Harbor Edge-Native Config pack" url="/integrations/packs/?pack=harbor-edge-native-config#enable-image-download-from-outside-of-harbor"/> documentation.
<!-- prettier-ignore-end -->

:::preview

:::

![Local Harbor Registry Architecture](/clusters_edge_networking_local_harbor_architecture.webp)

## Prerequisites

- At least one Edge host registered with your Palette account with an AMD64 or x86_64 processor architecture.

- Each of your Edge hosts must have at least 4 CPUs and 8 GB of RAM.

  - For single-node clusters, where there is only one Edge host handling both control plane and worker capabilities,
    your Edge host must have at least 6 CPUs and 12 GB of RAM.

- At least 300 GB of persistent storage. The actual amount of storage required depends on the size of your images.

- An Edge cluster profile. For information about how to create a cluster profile for Edge, refer to
  [Model Edge Cluster Profile](../../site-deployment/model-profile.md).

## Enable Local Harbor Registry

1. Log in to [Palette](https://console.spectrocloud.com).

2. Navigate to the left **Main Menu** and select **Profiles**.

3. Select the profile you plan to use for deployment and create a new version of the profile.

4. If the profile does not already have a storage layer, click **Add New Pack** to add a storage pack. You can choose
   any storage pack for your storage layer.

5. Select the Kubernetes layer of the profile. Under `cluster.config.kube-apiserver-arg`, remove `AlwaysPullImages` from
   the list item `enable-admission-plugins`:

   ```yaml {7}
   kube-apiserver-arg:
     - anonymous-auth=true
     - profiling=false
     - disable-admission-plugins=AlwaysAdmit
     - default-not-ready-toleration-seconds=60
     - default-unreachable-toleration-seconds=60
     - enable-admission-plugins=NamespaceLifecycle,ServiceAccount,NodeRestriction
   ```

<!-- prettier-ignore-start -->
6. Click **Add New Pack** and search for the **Harbor Edge Native Config** pack. Add the pack to your cluster profile.
   For more information about the pack and its parameters, refer to <VersionedLink text="Harbor Edge Native Config pack documentation" url="/integrations/packs/?pack=harbor-edge-native-config"/>.

<!-- prettier-ignore-end -->

7. In the `harbor-config.storage` parameter, make sure you allocate enough storage in the `registry` field to store all
   your images.

8. Click **Save Changes**.

9. Deploy a new Edge cluster with your updated profile. Or, if you have an active cluster, update the cluster to use the
   new version of the cluster profile. The initial download of the images will require a connection to the external
   network as the images are sourced from the original repository. Subsequent image pulls are sourced from the local
   Harbor registry.

## Validation

1. Log in to [Palette](https://console.spectrocloud.com).

2. From the left **Main Menu**, navigate to **Clusters**. Choose your Edge cluster.

3. Navigate to the **Nodes** tab, in the **Private Ips** column, you can find the IP addresses of your Edge hosts.

4. Ensure you have network access to your Edge hosts. Open a new tab in your browser and navigate to
   `https://NODE_IP:30003` and replace `NODE_IP` with any IP address in your cluster. NodePort-type services are exposed
   on the same port on all nodes in your cluster. If you changed the HTTPS port in the configurations, replace the port
   with the HTTPS port you used.

5. If you didn't provide a certificate or used a self-signed certificate, your browser might warn you about an unsafe
   connection. Dismiss the warning, and you will be directed to Harbor's web UI. If you are using Google Chrome, you can
   click anywhere in your browser tab and type `thisisunsafe` using your keyboard to dismiss the warning.

<!-- prettier-ignore-start -->

6. Type in your credentials to log in to Harbor. The username is always `admin`. The password is what you configured
   during cluster creation. If you don't know your password, refer to <VersionedLink text="Retrieve Harbor Credentials" url="/integrations/packs/?pack=harbor-edge-native-config#retrieve-harbor-credentials"/> to retrieve your
   password.

<!-- prettier-ignore-end -->

7. In the **Projects** view, select the **spectro-images** project.

8. Confirm that all images required by the cluster are stored in the project.
