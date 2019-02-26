import hudson.model.*
import jenkins.model.*
import hudson.slaves.*
import hudson.model.Node.Mode

println ''
println '***** LOADING CREATE NODE SCRIPT *****'

def agents = [
//    [name: 'centos_gradle',
//     description: 'Centos Gradle Node',
//     home: '/tmp/workspace',
//     executors: 3,
//     labels: ''
//    ]
]
agents.each {
    //DumbSlave dumb = new DumbSlave(it.name, // Agent name, usually matches the host computer's machine name
    //        it.description,                 // Agent description
    //        it.home,                        // Workspace on the agent's computer
    //        it.executors,                   // Number of executors
    //        Mode.NORMAL,                    // "Usage" field, EXCLUSIVE is "only tied to node", NORMAL is "any"
    //        it.labels,                      // Labels
    //        new JNLPLauncher(),             // Launch strategy, JNLP is the Java Web Start setting services use
    //        RetentionStrategy.INSTANCE)     // Is the "Availability" field and INSTANCE means "Always"
    DumbSlave dumb = new DumbSlave(it.name, // Agent name, usually matches the host computer's machine name
            it.home,                        // Workspace on the agent's computer
            new JNLPLauncher(),             // Launch strategy, JNLP is the Java Web Start setting services use
            )
    dumb.mode = Node.Mode.NORMAL
    dumb.retentionStrategy = new RetentionStrategy.Always()
    dumb.numExecutors = it.executors
    dumb.nodeDescription = it.description
    dumb.labelString = it.labels
    Jenkins.instance.addNode(dumb)
}


println "Nodes have been created successfully."

println '***** CREATE NODE SCRIPT COMPLETE *****'
println ''
