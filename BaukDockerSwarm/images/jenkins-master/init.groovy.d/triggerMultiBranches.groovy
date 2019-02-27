#!groovy
import jenkins.model.*
import jenkins.model.*;

sleep 5
int counter = 0
int max_count = 100
while(Jenkins.instance.slaves.size() == 0 && counter < max_count){
    sleep 1
    counter += 1
    println "Waiting for Jenkins to start..."
}
if(counter >= max_count){
    println """
    
    ERROR: Could not wait long enough for Jenkins to start (No nodes detected after ${max_count} seconds)
    ERROR: Not triggering Multibranch pipelines
    
    """
}
sleep 5


Jenkins.instance.allItems(org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject).each { it ->
    println "Scanning Multibranch pipeline: "+it
    it.doBuild()
}
