#!groovy
import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule
import org.jenkinsci.plugins.*
import com.michelin.cio.hudson.plugins.rolestrategy.*

// GLOBAL VARIABLES
def instance = Jenkins.getInstance()
def env = System.getenv()
def access = [ // TODO: Slurp from URL. Taken from: https://gist.github.com/mllrjb/ccfd3315b7546ae8e8382ff693b34d7f
    admins  : ["anonymous"],
    builders: [],
    readers : []
]
// TODO: Make customizable with a json config file, URL above - but better, so just one big map


println ''
println '***** LOADING JENKINS ROLES SCRIPT *****'

println 'Setting up Role based Authentication'
def roleBasedAuthenticationStrategy = new RoleBasedAuthorizationStrategy()
instance.setAuthorizationStrategy(roleBasedAuthenticationStrategy)
permissionIds = [
    // 'hudson.model.Hudson.Read',
    // 'hudson.model.Item.Discover',
    // 'hudson.model.Item.Read',
    // 'hudson.model.Item.Build',
    // 'hudson.model.Item.Cancel',
    // 'hudson.model.Item.Workspace'
]
// Get list of all permissions for admin user
for (def group : new RoleBasedAuthorizationStrategy.DescriptorImpl().getGroups(RoleBasedAuthorizationStrategy.GLOBAL)) {
    for (def permission : group) {
        permissionIds.add(permission.getId())
    }
}
println 'Setting up admin as does not come pre-set unless through gui...'
roleBasedAuthenticationStrategy.doAddRole(RoleBasedAuthorizationStrategy.GLOBAL, 'admin', permissionIds.join(','), 'true', null)
roleBasedAuthenticationStrategy.doAssignRole(RoleBasedAuthorizationStrategy.GLOBAL, 'admin', 'jenkins_admin')

// TODO: pending fix to role-strategy plugin, there needs to be at least one role of each type present
roleBasedAuthenticationStrategy.doAddRole(RoleBasedAuthorizationStrategy.PROJECT, 'admin', permissionIds.join(','), 'false', null)
roleBasedAuthenticationStrategy.doAssignRole(RoleBasedAuthorizationStrategy.PROJECT, 'admin', 'jenkins_admin')

println 'Saving Changes...'
instance.save()


println '***** JENKINS ROLES SCRIPT COMPLETE *****'
println ''

