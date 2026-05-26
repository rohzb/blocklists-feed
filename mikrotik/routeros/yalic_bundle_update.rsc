:global yalicBundleUpdate do={
    :local listName "malware"
    :local bundleBaseUrl "https://example.com/malware.bundle"
    :local backupList ($listName . "_old")
    :local indexFile "yalic-bundle-index.txt"
    :local blockFile "yalic-bundle-block.txt"

    # prepare rollback list name
    /ip firewall address-list remove [find where list=$backupList]
    /ipv6 firewall address-list remove [find where list=$backupList]
    /ip firewall address-list set [find where list=$listName] list=$backupList
    /ipv6 firewall address-list set [find where list=$listName] list=$backupList

    :local indexUrl $bundleBaseUrl
    :if ([:pick $indexUrl ([:len $indexUrl] - 1) [:len $indexUrl]] != "/") do={ :set indexUrl ($indexUrl . "/") }
    :set indexUrl ($indexUrl . "index.txt")

    :do {
        /tool fetch url=$indexUrl mode=https dst-path=$indexFile

        # loop 1: iterate block files from index
        :foreach line in=[:deserialize [:tolf [/file get $indexFile contents]] delimiter="\n" from=dsv options=dsv.plain] do={
            :set line [:tostr $line]
            :if (($line = "") || ($line = "v1")) do={ :continue }

            :local t [:find $line "\t"]
            :if ($t = nil) do={ :continue }
            :local blockName [:pick $line 0 $t]
            :local blockUrl ($bundleBaseUrl . "/" . $blockName)
            /tool fetch url=$blockUrl mode=https dst-path=$blockFile

            # loop 2: iterate block records and add to new list
            :foreach record in=[:deserialize [:tolf [/file get $blockFile contents]] delimiter="\n" from=dsv options=dsv.plain] do={
                :set record [:tostr $record]
                :local hashPos [:find $record "#"]
                :if ($hashPos != nil) do={ :set record [:pick $record 0 $hashPos] }
                :set record [:trim $record]
                :if ($record = "") do={ :continue }
                :local value $record
                :if ([:find $value ":"] != nil) do={
                    /ipv6 firewall address-list add list=$listName address=$value
                } else={
                    /ip firewall address-list add list=$listName address=$value
                }
            }
        }

        # success: old list no longer needed
        /ip firewall address-list remove [find where list=$backupList]
        /ipv6 firewall address-list remove [find where list=$backupList]
        :log info ("yalic_bundle_update: success list=" . $listName)
    } on-error={
        # failure: drop new list and restore old
        /ip firewall address-list remove [find where list=$listName]
        /ipv6 firewall address-list remove [find where list=$listName]
        /ip firewall address-list set [find where list=$backupList] list=$listName
        /ipv6 firewall address-list set [find where list=$backupList] list=$listName
        :log warning ("yalic_bundle_update: failed, restored " . $listName)
        :error "bundle update failed"
    }
}
