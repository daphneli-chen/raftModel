/*
log matching property:
if any two distinct log entries have the same term number and the same index then they will store the exact same command and be identical in all the preceding entries 
simulates a leader getting a new message from a client, must send that message to all other noes and if gets a succesful reply then everyone increments commit index
if we can get 
*/
#define CLUSTER_SIZE 3
#define MAX_LOG_LENGTH 12
#define FOLLOWER 0
#define CANDIDATE 1
#define LEADER 2
#define FALSE 0
#define TRUE 1

typedef log {
    byte term[MAX_LOG_LENGTH]; //the term of the entry
    byte command[MAX_LOG_LENGTH] //what the command is
}
typedef leader {
    byte id;
    int nextIndex[CLUSTER_SIZE];
    // byte matchIndex[CLUSTER_SIZE]
}
typedef node {
    byte currentTerm;
    byte lastLogIndex;
    // byte commitIndex
}
log logs[CLUSTER_SIZE];
//byte commitIndex[CLUSTER_SIZE];
byte status[CLUSTER_SIZE];
//leader lead;
node nodes[CLUSTER_SIZE];
bool logsMatch = FALSE;


inline AppendEntries(leaderTerm, prevLogIndex, prevLogTerm, self, res) {   
    if
    :: leaderTerm < nodes[self].currentTerm -> res = FALSE;
    :: logs[self].term[prevLogIndex] != prevLogTerm -> res = FALSE;
    :: else -> res = TRUE;
    fi;

    if //if we are going to append
    :: res ->
        if 
        :: prevLogIndex < nodes[self].lastLogIndex ->
            int j; //prevlogindex is the last index where logs are consistent
            for (j: prevLogIndex + 1 .. MAX_LOG_LENGTH - 1) { //clearing all the log entries in the follower beyond prevLogIndex
                logs[self].term[j] = 0; //0 will indicate not set
                logs[self].command[j] = 0;
            }
            nodes[self].lastLogIndex = prevLogIndex;
        :: else -> skip;
        fi;

        int ind = prevLogIndex + 1;
        do 
        :: logs[lead.id].term[ind] != 0 -> //while there are logs in the leader to append, change the follower's logs to match the leaders
            logs[self].term[ind] = logs[lead.id].term[ind];
            logs[self].command[ind] = logs[lead.id].command[ind];
            nodes[self].lastLogIndex = nodes[self].lastLogIndex + 1; //increment how long your log is
        :: ind > nodes[lead.id].lastLogIndex -> break;
        :: else -> break;
        od;

    :: else -> skip;
    fi;


}

inline appendEntryInPeer(peer, lastIndex, appended) {
    byte leadId = lead.id;
    int prevIndex = lead.nextIndex[peer];
    prevIndex = prevIndex - 1;
    byte prevTerm = logs[lead.id].term[prevIndex];
    AppendEntries(nodes[leadId].currentTerm, prevIndex, prevTerm, peer, appended);
    if
    :: !appended -> 
        lead.nextIndex[peer] = lead.nextIndex[peer] - 1;
    :: else -> 
        lead.nextIndex[peer] = lastIndex + 1; //updating appropriate maps, we are now done with this peer
        appended = TRUE;
    fi;


}

active proctype main() {
    //initialize logs for each node (?) - term should be ascending, length should be randomly determined, contents randomly determined
    //need to initialize where term nor command = 0 ever
    int i;
    for (i: 0.. CLUSTER_SIZE - 1) {
        status[i] = FOLLOWER;
    }
    leader lead;
    //INITIALIZATION OF THE LEADER
    status[0] = LEADER;
    //Terms of leader are 1, 1, 1, 4, 4, 5, 5, 6, 6, 6
    logs[0].term[0] = 1; logs[0].term[1] = 1; logs[0].term[2] = 1; 
    logs[0].term[3] = 4;  logs[0].term[4] = 4;  
    logs[0].term[5] = 5; logs[0].term[6] = 5;
    logs[0].term[7] = 6; logs[0].term[8] = 6; logs[0].term[9] = 6;
    logs[0].term[10] = 0; logs[0].term[11] = 0; // these indicate nonexistent log entries
    int entry;
    for (entry: 0 .. MAX_LOG_LENGTH - 1) {
        logs[0].command[entry] = 5;
    }
    logs[0].command[10] = 0;
    logs[0].command[11] = 0;
    nodes[0].lastLogIndex = 9; nodes[0].currentTerm = 6;
    lead.id = 0;
    int node;
    for (node: 0 .. CLUSTER_SIZE - 1) {
        lead.nextIndex[node] = 11; //initialized to leader's last log index + 1
    }

    //first follower has terms 1, 1, 1, 4, 4, 5, 5, 6, 6
    logs[1].term[0] = 1; logs[1].term[1] = 1; logs[1].term[2] = 1;
    logs[1].term[3] = 4; logs[1].term[4] = 4;
    logs[1].term[5] = 5; logs[1].term[6] = 5;
    logs[1].term[7] = 6; logs[1].term[8] = 6; 
    logs[1].term[9] = 0; logs[1].term[10] = 0; logs[1].term[11] = 0
    logs[1].command[0] = 5; logs[1].command[1] = 5; logs[1].command[2] = 5;
    logs[1].command[3] = 5; logs[1].command[4] = 5;
    logs[1].command[5] = 5; logs[1].command[6] = 5;
    logs[1].command[7] = 5; logs[1].command[8] = 5;
    logs[1].command[9] = 0; logs[1].command[10] = 0; logs[1].command[11] = 0;
    nodes[1].lastLogIndex = 8; nodes[1].currentTerm = 6;

    //second follower has terms 1, 1, 1, 4
    logs[2].term[0] = 1; logs[2].term[1] = 1; logs[2].term[2] = 1;
    logs[2].term[3] = 4; 
    logs[2].term[4] = 0; logs[2].term[5] = 0; logs[2].term[6] = 0; logs[2].term[7] = 0;
    logs[2].term[8] = 0; logs[2].term[9] = 0; logs[2].term[10] = 0; logs[2].term[11] = 0
    logs[2].command[0] = 5; logs[2].command[1] = 5; logs[2].command[2] = 5;
    logs[2].command[3] = 5; 
    logs[2].command[4] = 0; logs[2].command[5] = 0; logs[2].command[6] = 0; logs[2].command[7] = 0; 
    logs[2].command[8] = 0; logs[2].command[9] = 0; logs[2].command[10] = 0; logs[2].command[11] = 0;
    nodes[2].lastLogIndex = 3; nodes[2].currentTerm = 4;

    //third follower has terms 1, 1, 1, 4, 4, 5, 5, 6, 6, 6, 6
    logs[3].term[0] = 1; logs[3].term[1] = 1; logs[3].term[2] = 1; 
    logs[3].term[3] = 4;  logs[3].term[4] = 4;  
    logs[3].term[5] = 5; logs[3].term[6] = 5;
    logs[3].term[7] = 6; logs[3].term[8] = 6; logs[3].term[9] = 6; logs[3].term[10] = 6;
    logs[3].term[11] = 0; // these indicate nonexistent log entries
    for (entry: 0 .. MAX_LOG_LENGTH - 1) {
        logs[3].command[entry] = 5;
    }
    logs[3].command[11] = 0;
    nodes[3].lastLogIndex = 10; nodex[3].currentTerm = 6;

    //fourth follower has terms 1, 1, 1, 4, 4, 5, 5, 6, 6, 6, 7, 7
    logs[4].term[0] = 1; logs[4].term[1] = 1; logs[4].term[2] = 1; 
    logs[4].term[3] = 4;  logs[4].term[4] = 4;  
    logs[4].term[5] = 5; logs[4].term[6] = 5;
    logs[4].term[7] = 6; logs[4].term[8] = 6; logs[4].term[9] = 6;
    logs[4].term[10] = 7; logs[4].term[11] = 7;
    for (entry: 0 .. MAX_LOG_LENGTH - 1) {
        logs[4].command[entry] = 5;
    }
    logs[4].command[10] = 2;
    logs[4].command[11] = 2;
    nodes[4].lastLogIndex = 11; nodes[4].currentTerm = 7;

    //fifth follower has terms 1, 1, 1, 4, 4, 4, 4
    logs[5].term[0] = 1; logs[5].term[1] = 1; logs[5].term[2] = 1; 
    logs[5].term[3] = 4;  logs[5].term[4] = 4;  logs[5].term[5] = 4; logs[5].term[6] = 4;
    logs[5].term[7] = 0; logs[5].term[8] = 0; logs[5].term[9] = 0;
    logs[5].term[10] = 0; logs[5].term[11] = 0;
    for (entry: 0 .. 4) {
        logs[5].command[entry] = 5;
    }
    logs[5].term[5] = 3;
    logs[5].term[6] = 3;
    nodes[5].lastLogIndex = 6; nodes[5].currentTerm = 4;

    //sixth follower has terms 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 3
    logs[6].term[0] = 1; logs[6].term[1] = 1; logs[6].term[2] = 1; 
    logs[6].term[3] = 2;  logs[6].term[4] = 2;  logs[6].term[5] = 2; 
    logs[6].term[6] = 3; logs[6].term[7] = 3; logs[6].term[8] = 3; logs[6].term[9] = 3; logs[6].term[10] = 3; 
    logs[6].term[11] = 0;
    for (entry: 0 .. 10) {
        logs[6].command[entry] = 4;
    }
    logs[6].command[0] = 5;
    logs[6].command[1] = 5;
    logs[6].command[2] = 5;
    nodes[6].lastLogIndex = 10; nodes[6].currentTerm = 3;

    int i2;
    for(i2: 1 .. CLUSTER_SIZE - 1) {
        bool appended = FALSE;
        appendEntryInPeer(i2, nodes[0].lastLogIndex, appended);
        do
        :: !appended ->
            appendEntryInPeer(i2, nodes[0].lastLogIndex, appended);
        :: else -> break;
        od;
    }
    //TODO: check that the logs all match
    bool matches = TRUE;
    int j;
    for(j: 1 .. CLUSTER_SIZE - 1) {
        int entry;
        for(entry: 0 .. nodes[lead.id].lastLogIndex) {
            if
            :: logs[j].term[entry] != logs[lead.id].term[entry] || logs[j].command[entry] != logs[lead.id].command[entry] ->
                matches = FALSE;
            :: else -> skip;
            fi;
        }
    }
    logsMatch = matches;
}

ltl one_leader {
    always(
        eventually(logsMatch == TRUE) //the logs all match
    );
}
