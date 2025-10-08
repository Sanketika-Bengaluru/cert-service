# Play Framework & Akka to Pekko Migration Compatibility Report

## Executive Summary

This report analyzes the `cert-service` repository for upgrading Play Framework and migrating from Akka to Apache Pekko. The analysis covers current dependencies, compatibility issues, migration paths, drawbacks, and benefits.

---

## Current State Analysis

### 1. Build System
- **Build Tool**: Maven (NOT SBT as mentioned in the problem statement)
- **Maven Version**: 3.9.11
- **Java Version**: Currently using Java 11 (compiler target) with Java 17 runtime
- **Build Plugin**: `play2-maven-plugin` version 1.0.0-rc5

### 2. Current Framework Versions

#### Play Framework
- **Current Version**: Play 2.7.2 (Released ~2019)
- **Scala Version**: 2.11.12
- **Status**: Significantly outdated

#### Akka Dependencies
- **Akka Actor**: 2.5.22
- **Akka Remote**: 2.5.22
- **Akka Stream**: 2.5.22 (transitive)
- **Akka HTTP**: 10.1.8 (transitive from Play)
- **Akka TestKit**: 2.5.16
- **Status**: All Akka 2.5.x versions are under old Apache 2.0 license

### 3. Akka Usage Pattern Analysis

The codebase uses Akka in the following ways:

#### Core Actor System Components
1. **Base Actor**: `org.sunbird.BaseActor` extends `akka.actor.UntypedAbstractActor`
2. **Actor Implementations** (4 actors):
   - `HealthActor`
   - `CertificateGeneratorActor`
   - `CertificateVerifierActor`
   - `TemplateValidateActor`

#### Actor System Integration Points
- **Dependency Injection**: Uses Play's `AkkaGuiceSupport` for actor binding
- **Actor Routing**: Uses Akka routing with `FromConfig` and `RouterConfig`
- **Request Handling**: Uses `Patterns.ask()` for actor communication
- **Future Conversion**: Uses `scala.compat.java8.FutureConverters` for Scala-Java interop
- **Signal Handling**: Uses `ActorSystem` for graceful shutdown
- **Remote Communication**: Akka Remote is configured (port 8088) in application.conf

#### Files with Akka Dependencies (17 imports total)
1. Service layer (controllers):
   - `BaseController.java`
   - `RequestHandler.java`
   - `CertsGenerationController.java`
   - `HealthController.java`

2. Actor layer:
   - `BaseActor.java`
   - All actor implementations

3. Module/Infrastructure:
   - `ActorStartModule.java`
   - `SignalHandler.java`

4. Tests:
   - `CertificateGeneratorActorTest.java`
   - `BaseApplicationTest.java`
   - `DummyActor.java`

### 4. Configuration Analysis

**application.conf** contains extensive Akka configuration:
- Actor system configuration with custom dispatchers
- Router configurations for all actors
- Remote actor configuration (Akka Remote on port 8088)
- Custom serialization bindings
- Fork-join executor configurations

---

## Migration Paths

### Path 1: Upgrade Play Framework Only (Keep Akka 2.5.x)

**Target Versions:**
- Play Framework: 2.8.x (Last version with Akka 2.5.x/2.6.x support)
- Scala: 2.12.x or 2.13.x
- Akka: Stay on 2.5.x or upgrade to 2.6.x (both Apache 2.0 licensed)

**Advantages:**
- Akka remains under Apache 2.0 license
- Moderate complexity
- Play 2.8.x is stable and well-documented

**Disadvantages:**
- Play 2.8.x reached end-of-life
- No long-term support
- Future security patches unlikely

### Path 2: Upgrade to Play 2.9.x with Pekko

**Target Versions:**
- Play Framework: 2.9.x (First version with Pekko support)
- Scala: 2.13.x or 3.x
- Pekko: 1.0.x (Apache Pekko fork of Akka)

**Advantages:**
- Modern Play version with active support
- Apache 2.0 licensed Pekko
- Long-term sustainability

**Disadvantages:**
- Most complex migration
- Requires Scala version upgrade
- Breaking API changes in Play 2.9.x

### Path 3: Upgrade to Play 3.0.x with Pekko (RECOMMENDED)

**Target Versions:**
- Play Framework: 3.0.x (Latest stable)
- Scala: 2.13.x or 3.x
- Java: Minimum Java 11, recommended Java 17+
- Pekko: 1.0.x or 1.1.x

**Advantages:**
- Latest features and security patches
- Full Pekko integration
- Modern Java support
- Active community and commercial support available
- Best long-term investment

**Disadvantages:**
- Highest migration effort
- Significant breaking changes from Play 2.7.x
- Requires code refactoring

---

## Detailed Compatibility Issues

### 1. Build System Issues

#### Maven Play Plugin
**Issue**: The `play2-maven-plugin` (version 1.0.0-rc5) used in the project:
- Is in release candidate status
- Has limited support for Play 3.x
- May require alternative build approaches

**Solutions**:
- Consider switching to SBT (Play's native build tool)
- Use alternative Maven plugins (if available for Play 3.x)
- Explore Play's built-in build capabilities

### 2. Scala Version Compatibility

**Current**: Scala 2.11.12
**Required for Play 3.0.x**: Scala 2.13.x or 3.x

**Impact**:
- Binary incompatibility between Scala 2.11 and 2.13
- All Scala dependencies need to be updated
- Potential source code changes for Scala 3.x

### 3. Java API Changes

#### Play 2.x to 3.x Changes
- HTTP request/response handling refactored
- Updated dependency injection patterns
- Changes in routing DSL
- Filter API modifications

#### Akka to Pekko Package Rename
**All** Akka imports need to be changed:
```java
// Current (Akka)
import akka.actor.ActorRef;
import akka.actor.ActorSystem;
import akka.actor.UntypedAbstractActor;
import akka.pattern.Patterns;
import akka.routing.FromConfig;

// New (Pekko)
import org.apache.pekko.actor.ActorRef;
import org.apache.pekko.actor.ActorSystem;
import org.apache.pekko.actor.UntypedAbstractActor;
import org.apache.pekko.pattern.Patterns;
import org.apache.pekko.routing.FromConfig;
```

**Affected**: 17+ import statements across 10+ files

### 4. Configuration Changes

**application.conf** needs updates:
```hocon
# Current (Akka)
akka {
  actor {
    provider = "akka.actor.LocalActorRefProvider"
  }
}

# New (Pekko)
pekko {
  actor {
    provider = "org.apache.pekko.actor.LocalActorRefProvider"
  }
}
```

### 5. Play Integration Changes

#### Current Integration (Play + Akka)
- `play.libs.akka.AkkaGuiceSupport` for actor injection
- `play-akka-http-server` for HTTP server

#### New Integration (Play + Pekko)
- `play.libs.pekko.PekkoGuiceSupport` for actor injection
- `play-pekko-http-server` for HTTP server

### 6. Testing Framework Changes

- `akka-testkit` → `pekko-testkit`
- Test utilities need updates
- `TestKit` import changes

### 7. Remote Actor System

**Current**: Uses Akka Remote (netty.tcp on port 8088)

**Considerations**:
- Pekko maintains remote actor compatibility
- Protocol should remain compatible
- Configuration keys change but functionality preserved

---

## Detailed Migration Steps (RECOMMENDED PATH - Play 3.0.x + Pekko)

### Phase 1: Preparation & Assessment
1. **Code Freeze**: Establish a migration branch
2. **Backup**: Ensure all changes are version controlled
3. **Test Coverage**: Verify existing tests pass
4. **Documentation**: Document current behavior

### Phase 2: Update Build Configuration

#### 2.1 Update Parent POM
```xml
<properties>
    <play2.version>3.0.5</play2.version>
    <scala.major.version>2.13</scala.major.version>
    <scala.version>2.13.12</scala.version>
    <pekko.version>1.0.2</pekko.version>
    <maven.compiler.source>11</maven.compiler.source>
    <maven.compiler.target>11</maven.compiler.target>
</properties>
```

#### 2.2 Update Dependencies in service/pom.xml
Replace Akka dependencies with Pekko:
```xml
<!-- Replace akka-actor -->
<dependency>
    <groupId>org.apache.pekko</groupId>
    <artifactId>pekko-actor_${scala.major.version}</artifactId>
    <version>${pekko.version}</version>
</dependency>

<!-- Replace akka-remote -->
<dependency>
    <groupId>org.apache.pekko</groupId>
    <artifactId>pekko-remote_${scala.major.version}</artifactId>
    <version>${pekko.version}</version>
</dependency>

<!-- Replace akka-testkit -->
<dependency>
    <groupId>org.apache.pekko</groupId>
    <artifactId>pekko-testkit_${scala.major.version}</artifactId>
    <version>${pekko.version}</version>
    <scope>test</scope>
</dependency>
```

#### 2.3 Update Play Dependencies
```xml
<dependency>
    <groupId>com.typesafe.play</groupId>
    <artifactId>play_${scala.major.version}</artifactId>
    <version>${play2.version}</version>
</dependency>
```

### Phase 3: Code Migration

#### 3.1 Package Rename (Automated)
Use find-and-replace across all Java files:
- `import akka.` → `import org.apache.pekko.`
- `import play.libs.akka.` → `import play.libs.pekko.`

#### 3.2 Update Base Classes
**BaseActor.java**:
```java
// Before
import akka.actor.UntypedAbstractActor;
public abstract class BaseActor extends UntypedAbstractActor {

// After
import org.apache.pekko.actor.typed.javadsl.AbstractBehavior;
// Consider migrating to Typed Actors (recommended) or
import org.apache.pekko.actor.UntypedAbstractActor;
public abstract class BaseActor extends UntypedAbstractActor {
```

#### 3.3 Update Actor Module
**ActorStartModule.java**:
```java
// Before
import akka.routing.FromConfig;
import play.libs.akka.AkkaGuiceSupport;
public class ActorStartModule extends AbstractModule implements AkkaGuiceSupport {

// After
import org.apache.pekko.routing.FromConfig;
import play.libs.pekko.PekkoGuiceSupport;
public class ActorStartModule extends AbstractModule implements PekkoGuiceSupport {
```

#### 3.4 Update Controllers
**RequestHandler.java**:
```java
// Before
import akka.actor.ActorRef;
import akka.pattern.Patterns;
import akka.util.Timeout;
import scala.compat.java8.FutureConverters;

// After
import org.apache.pekko.actor.ActorRef;
import org.apache.pekko.pattern.Patterns;
import org.apache.pekko.util.Timeout;
import scala.jdk.javaapi.FutureConverters;  // Note: scala.compat.java8 → scala.jdk.javaapi
```

### Phase 4: Configuration Migration

#### 4.1 Update application.conf
**Complete Configuration Replacement**:
```hocon
# Replace all "akka" sections with "pekko"
pekko {
  loggers = ["org.apache.pekko.event.slf4j.Slf4jLogger"]
  loglevel = "INFO"
  stdout-loglevel = "DEBUG"
  logging-filter = "org.apache.pekko.event.slf4j.Slf4jLoggingFilter"
  
  actor {
    provider = "org.apache.pekko.actor.LocalActorRefProvider"
    serializers {
      java = "org.apache.pekko.serialization.JavaSerializer"
    }
    serialization-bindings {
      "org.sunbird.request.Request" = java
      "org.sunbird.response.Response" = java
    }
    # ... rest of configuration
  }
  
  remote {
    artery {
      transport = tcp
      canonical.hostname = "127.0.0.1"
      canonical.port = 8088
    }
  }
}
```

#### 4.2 Update Play Modules
```hocon
play.modules {
  enabled += utils.module.StartModule
  enabled += utils.module.ActorStartModule
}
```

### Phase 5: Test Migration

#### 5.1 Update Test Dependencies
Replace test utilities:
```java
// Before
import akka.testkit.javadsl.TestKit;
import akka.actor.ActorSystem;

// After
import org.apache.pekko.testkit.javadsl.TestKit;
import org.apache.pekko.actor.ActorSystem;
```

#### 5.2 Update Test Configurations
Create test-specific application.conf with Pekko configuration

### Phase 6: Validation & Testing

1. **Compile**: `mvn clean compile`
2. **Unit Tests**: `mvn test`
3. **Integration Tests**: Run all integration test suites
4. **Manual Testing**: Test all API endpoints
5. **Performance Testing**: Compare performance metrics
6. **Load Testing**: Verify under load conditions

---

## Risk Assessment

### High Risk Areas

1. **Remote Actor Communication**
   - **Risk**: Protocol compatibility issues between Akka and Pekko remote
   - **Mitigation**: Phased rollout, maintain backward compatibility layer

2. **Serialization**
   - **Risk**: Binary incompatibility in serialized messages
   - **Mitigation**: Test serialization thoroughly, consider versioning

3. **Third-Party Dependencies**
   - **Risk**: Dependencies may still depend on Akka
   - **Mitigation**: Audit all transitive dependencies

4. **Performance Regression**
   - **Risk**: Performance characteristics may differ
   - **Mitigation**: Comprehensive performance testing

### Medium Risk Areas

1. **Configuration Changes**
   - **Risk**: Typos or missing configurations
   - **Mitigation**: Automated configuration validation

2. **Future Conversion**
   - **Risk**: scala.compat.java8 vs scala.jdk.javaapi differences
   - **Mitigation**: Thorough testing of async operations

3. **Actor Supervision**
   - **Risk**: Subtle differences in actor lifecycle
   - **Mitigation**: Test error handling thoroughly

### Low Risk Areas

1. **Business Logic**
   - **Risk**: Core business logic unchanged
   - **Mitigation**: Unit tests should pass without changes

2. **Database Operations**
   - **Risk**: Unaffected by actor system
   - **Mitigation**: Existing tests cover this

---

## Benefits of Migration

### Licensing Benefits
1. **Open Source Compliance**: Apache 2.0 license is commercially friendly
2. **No Licensing Costs**: Avoid potential Lightbend/Akka commercial licensing
3. **Community-Driven**: Apache Software Foundation governance
4. **Legal Certainty**: Clear licensing terms for enterprise use

### Technical Benefits
1. **Long-Term Support**: Active Apache Pekko community
2. **Security Updates**: Regular security patches
3. **Modern Java Support**: Better Java 11+ integration
4. **Performance Improvements**: Optimizations in newer versions
5. **Bug Fixes**: Accumulated fixes from Akka 2.6.x+

### Organizational Benefits
1. **Future-Proofing**: Sustainable open-source path
2. **Community Contributions**: Can contribute back to Apache
3. **No Vendor Lock-In**: Open governance model
4. **Better Documentation**: Growing Pekko documentation

---

## Drawbacks of Migration

### Immediate Drawbacks
1. **Migration Effort**
   - **Estimated**: 40-80 hours for code changes
   - **Testing**: Additional 40-60 hours
   - **Total**: 80-140 hours (2-3.5 weeks effort)

2. **Service Disruption Risk**
   - Requires careful deployment planning
   - Potential downtime during rollout

3. **Team Learning Curve**
   - Team needs to learn Pekko-specific differences
   - New documentation and best practices

### Technical Drawbacks
1. **Build Complexity**
   - Maven plugin support for Play 3.x may be limited
   - May require SBT adoption

2. **Dependency Conflicts**
   - Potential conflicts during transition
   - Third-party libraries may lag in Pekko support

3. **Documentation Gaps**
   - Pekko documentation still maturing
   - Fewer Stack Overflow answers vs Akka

### Organizational Drawbacks
1. **Resource Allocation**
   - Requires dedicated developer time
   - QA/Testing resources needed

2. **Deployment Risk**
   - New dependencies in production
   - Potential rollback complexity

---

## Alternative Approaches

### Option A: Stay on Akka 2.5.x/2.6.x
**Pros**: No migration effort, Apache 2.0 licensed
**Cons**: No future updates, security vulnerabilities, technical debt

### Option B: Migrate to Akka 2.6.x Only
**Pros**: Simpler migration, still Apache 2.0
**Cons**: Future licensing uncertainty, limited long-term viability

### Option C: Complete Rewrite Without Actors
**Pros**: Modern architecture, no actor complexity
**Cons**: Massive effort, complete rewrite needed

### Option D: Hybrid Approach
**Pros**: Gradual migration, reduced risk
**Cons**: Increased complexity, longer timeline

---

## Recommendations

### Immediate Actions (Do NOT implement yet - analysis only)
1. **Approve Migration Strategy**: Review this report with stakeholders
2. **Allocate Resources**: Assign dedicated team (2-3 weeks)
3. **Create Migration Branch**: Establish isolated development branch
4. **Set Up Test Environment**: Prepare testing infrastructure

### Phase 1: Quick Wins (Week 1)
1. Upgrade to Play 2.8.x with Akka 2.6.x (both still Apache 2.0)
2. Update Java to 11 minimum
3. Comprehensive testing
4. Deploy to production

### Phase 2: Pekko Migration (Weeks 2-3)
1. Switch to Play 2.9.x or 3.0.x
2. Migrate Akka to Pekko
3. Update all configurations
4. Extensive testing

### Phase 3: Optimization (Week 4+)
1. Performance tuning
2. Consider Pekko Typed Actors (optional)
3. Documentation updates
4. Team training

---

## Estimated Timeline

### Conservative Estimate (Sequential)
- **Analysis & Planning**: 1 week
- **Build Configuration Updates**: 1-2 days
- **Code Migration**: 1 week
- **Testing & Bug Fixes**: 1-2 weeks
- **Documentation**: 2-3 days
- **Deployment & Validation**: 1 week
- **Total**: 4-6 weeks

### Aggressive Estimate (Parallel)
- **With Dedicated Team**: 2-3 weeks
- **With Automation Tools**: 1.5-2 weeks

---

## Cost-Benefit Analysis

### Migration Costs
- **Developer Time**: 80-140 hours @ $100/hr = $8,000-$14,000
- **QA Time**: 40-60 hours @ $80/hr = $3,200-$4,800
- **Infrastructure**: Minimal ($500-$1,000)
- **Total Estimated Cost**: $11,700-$19,800

### Staying with Akka Costs (if going commercial)
- **Lightbend License**: $5,000-$15,000/year (estimated)
- **Support Contract**: Additional costs
- **Over 5 Years**: $25,000-$75,000+

### ROI
- **Break-even**: 1-2 years
- **Long-term Savings**: Significant

---

## Conclusion

**Migration is RECOMMENDED** for the following reasons:

1. **Licensing Compliance**: Ensures open-source Apache 2.0 license
2. **Long-Term Viability**: Pekko has community backing and active development
3. **Technical Debt**: Addresses outdated Play 2.7.2 and Akka 2.5.22
4. **Manageable Scope**: The codebase has limited actor usage (4 actors, 17 imports)
5. **Clear Migration Path**: Well-documented Akka-to-Pekko migration

**Recommended Path**: Play 3.0.x with Pekko 1.0.x

The migration effort is justified given:
- Legal/licensing certainty
- Modern framework support
- Active community and security updates
- Relatively small codebase impact

---

## Appendix A: Key Dependencies Summary

### Current Dependencies
| Dependency | Current Version | Latest Version | Status |
|------------|----------------|----------------|--------|
| Play Framework | 2.7.2 | 3.0.5 | Outdated |
| Scala | 2.11.12 | 2.13.12 | Major upgrade needed |
| Akka Actor | 2.5.22 | 2.8.x (BSL) / Pekko 1.0.2 | License changed |
| Akka Remote | 2.5.22 | 2.8.x (BSL) / Pekko 1.0.2 | License changed |
| Akka HTTP | 10.1.8 | 10.5.x (BSL) / Pekko HTTP 1.0.x | License changed |
| Java | 11 (target) | 17-21 | Modern |

### Target Dependencies (Recommended)
| Dependency | Target Version | License | Notes |
|------------|----------------|---------|-------|
| Play Framework | 3.0.5 | Apache 2.0 | Latest stable |
| Scala | 2.13.12 | Apache 2.0 | Required for Play 3.x |
| Pekko Actor | 1.0.2 | Apache 2.0 | Akka fork |
| Pekko Remote | 1.0.2 | Apache 2.0 | Akka fork |
| Pekko HTTP | 1.0.1 | Apache 2.0 | Akka HTTP fork |
| Java | 11+ | N/A | Min version |

---

## Appendix B: Files Requiring Changes

### Java Source Files (10 files)
1. `/all-actors/src/main/java/org/sunbird/BaseActor.java`
2. `/service/app/controllers/BaseController.java`
3. `/service/app/controllers/RequestHandler.java`
4. `/service/app/controllers/certs/CertsGenerationController.java`
5. `/service/app/controllers/health/HealthController.java`
6. `/service/app/utils/module/ActorStartModule.java`
7. `/service/app/utils/module/SignalHandler.java`
8. `/service/test/controllers/DummyActor.java`
9. `/service/test/controllers/BaseApplicationTest.java`
10. `/all-actors/src/test/java/org/sunbird/cert/actor/CertificateGeneratorActorTest.java`

### Configuration Files (2 files)
1. `/service/conf/application.conf`
2. `/pom.xml` (parent and child POMs - 5 files total)

### Build Files (5 files)
1. `/pom.xml`
2. `/service/pom.xml`
3. `/all-actors/pom.xml`
4. `/cert-processor/pom.xml` (potentially)
5. `/es-utils/pom.xml` (potentially)

**Total Files**: ~17 files requiring modification

---

## Appendix C: Maven vs SBT Consideration

### Current State: Maven
- Uses `play2-maven-plugin` version 1.0.0-rc5
- Limited support for Play 3.x
- May have compatibility issues

### Option 1: Stay with Maven
**Pros**: 
- No build system migration
- Team familiarity

**Cons**: 
- Limited Play 3.x support
- Plugin may not be maintained
- Potential compatibility issues

### Option 2: Migrate to SBT
**Pros**: 
- Native Play Framework build tool
- Better Play 3.x support
- Active community

**Cons**: 
- Additional migration effort
- Team learning curve
- Different build semantics

### Recommendation
**Try Maven first**, migrate to SBT only if significant issues arise. The problem statement mentions "using SBT" but this is likely a misunderstanding - the project uses Maven, not SBT.

---

## Appendix D: Testing Strategy

### Unit Tests
- All existing unit tests should pass after migration
- Focus on actor behavior tests
- Verify serialization/deserialization

### Integration Tests
- End-to-end API testing
- Health check endpoints
- Certificate generation flows
- Certificate verification flows

### Performance Tests
- Actor throughput benchmarks
- Response time metrics
- Memory usage profiling
- Remote actor communication latency

### Compatibility Tests
- Backward compatibility with existing clients
- Database interaction verification
- External service integration checks

---

## Appendix E: Rollback Strategy

### Pre-Migration
1. **Tag Current Version**: Create git tag for current production state
2. **Backup Database**: Ensure data backup exists
3. **Document Configuration**: Save all current configurations

### During Migration
1. **Feature Flags**: Use feature flags for gradual rollout
2. **Blue-Green Deployment**: Maintain old version running in parallel
3. **Monitoring**: Enhanced monitoring during migration

### Rollback Plan
1. **Quick Rollback**: Revert to previous version via git tag
2. **Database**: Ensure schema compatibility
3. **Configuration**: Keep old configs backed up
4. **Estimated Rollback Time**: 15-30 minutes

---

## Appendix F: Resources & References

### Documentation
- Play Framework 3.0: https://www.playframework.com/documentation/3.0.x/
- Apache Pekko: https://pekko.apache.org/docs/pekko/current/
- Akka to Pekko Migration Guide: https://pekko.apache.org/docs/pekko/current/project/migration-guides.html

### Community Support
- Play Framework Discourse: https://github.com/playframework/playframework/discussions
- Apache Pekko Discussions: https://github.com/apache/pekko/discussions
- Stack Overflow: Tagged questions for Play and Pekko

### Tools
- Automated Code Migration: Custom scripts for package renaming
- Dependency Analysis: Maven dependency plugin
- Testing Tools: Existing JUnit infrastructure

---

**Report Prepared**: December 2024  
**Report Version**: 1.0  
**Status**: ANALYSIS ONLY - NO CODE CHANGES IMPLEMENTED  
**Next Steps**: Stakeholder review and approval before implementation

